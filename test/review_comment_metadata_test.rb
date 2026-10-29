# frozen_string_literal: true

# Run with ruby --disable-gems test/review_comment_metadata_test.rb.
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'fileutils'

script = File.expand_path('../gh-view-md', __dir__)
Dir.mktmpdir('gh-view-md-test-') do |dir|
  # Exercise the real CLI offline, including JSON decoding and thread rendering.
  File.write(File.join(dir, 'gh'), <<~'FAKE_GH')
    #!/usr/bin/env -S ruby --disable-gems
    require 'json'
    case ARGV.first(2)
    when ['pr', 'view']
      puts JSON.generate(
        'number' => 1, 'title' => 'Fixture PR', 'body' => 'PR description',
        'author' => { 'login' => 'author' }, 'createdAt' => '2026-01-01T00:00:00Z',
        'closedAt' => '2026-01-02T00:00:00Z', 'mergedAt' => nil,
        'additions' => 1, 'deletions' => 0, 'changedFiles' => 1,
        'comments' => [], 'reviews' => [], 'commits' => [], 'labels' => [], 'assignees' => []
      )
    when ['pr', 'diff']
      puts '+example'
    when ['api', 'repos/example/repo/pulls/1/comments']
      puts File.read(ENV.fetch('REVIEW_COMMENTS_FIXTURE'))
    when ['api', 'repos/example/repo/issues/1/timeline']
      puts '[]'
    when ['api', 'repos/example/repo/pulls/1']
      puts '{}'
    when ['api', 'repos/example/repo/issues/1/comments']
      # No images.
    else
      abort "Unexpected gh invocation: #{ARGV.inspect}"
    end
  FAKE_GH
  File.chmod(0o755, File.join(dir, 'gh'))

  comment = {
    'id' => 1, 'user' => { 'login' => 'reviewer' }, 'body' => 'Please adjust this line.',
    'created_at' => '2026-01-01T01:00:00Z',
    'html_url' => 'https://github.com/example/repo/pull/1#discussion_r1',
    'path' => 'example.rb', 'diff_hunk' => '@@ -1 +1 @@',
    'line' => 1, 'position' => 1
  }
  reply = comment.merge(
    'id' => 2, 'in_reply_to_id' => 1, 'user' => { 'login' => 'author' },
    'body' => 'Updated as requested.', 'created_at' => '2026-01-01T02:00:00Z',
    'html_url' => 'https://github.com/example/repo/pull/1#discussion_r2'
  )
  fixture = File.join(dir, 'comments.json')
  env = { 'PATH' => "#{dir}:#{ENV.fetch('PATH')}", 'REVIEW_COMMENTS_FIXTURE' => fixture,
          'TMPDIR' => dir }
  outputs = {}
  {
    'legacy payload' => {},
    'GitHub Copilot metadata' => { 'is_copilot_code_review' => false, 'copilot_code_review_sources' => [] },
    'future additive metadata' => { 'is_copilot_code_review' => true,
                                    'copilot_code_review_sources' => [{ 'type' => 'example' }],
                                    'future_api_field' => { 'nested' => true } }
  }.each do |name, metadata|
    File.write(fixture, JSON.generate([comment.merge(metadata), reply.merge(metadata)]))
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, '--disable-gems', script,
                                          'https://github.com/example/repo/pull/1')
    raise "#{name}: CLI failed (#{status.exitstatus}): #{stderr}" unless status.success?
    raise "#{name}: unexpected stderr: #{stderr}" unless stderr.empty?
    ['# Pull Request #1:', 'PR description', '## Review thread on `example.rb`',
     '@@ -1 +1 @@', '## @reviewer [commented', 'Please adjust this line.',
     '### @author [replied', 'Updated as requested.', '#discussion_r1', '#discussion_r2'].each do |text|
      raise "#{name}: missing #{text.inspect}" unless stdout.include?(text)
    end
    raise "#{name}: lost thread grouping" unless stdout.scan('## Review thread on').length == 1
    outputs[name] = stdout
    puts "PASS: #{name}"
  end
  raise 'API metadata changed rendered content' unless outputs.values.uniq.length == 1
ensure
  FileUtils.rm_rf('/tmp/gh_issue/github.com/example/repo/pull/1')
end

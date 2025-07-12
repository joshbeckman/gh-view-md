# gh-view-md

A GitHub CLI extension that fetches GitHub issues and pull requests and renders them in markdown format, making them ideal for consumption by LLMs or markdown viewers.

## Installation

Install this GitHub CLI extension using:

```bash
gh extension install joshbeckman/gh-view-md
```

Or with the full URL:

```bash
gh extension install https://github.com/joshbeckman/gh-view-md
```

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) must be installed and authenticated
- Ruby runtime (the script is written in Ruby)
- Internet connection for downloading images and fetching GitHub data

## Usage

```bash
gh view-md <github_issue_or_pr_url> [options]
```

### Options

- `--max-diff LINES`: Maximum number of diff lines to show for pull requests (default: 800). When exceeded, only file names are shown.
- `-h, --help`: Show help message

### Examples

**View an issue:**
```bash
gh view-md https://github.com/owner/repo/issues/123
```

**View a pull request:**
```bash
gh view-md https://github.com/owner/repo/pull/456
```

**Limit diff output for large PRs:**
```bash
gh view-md --max-diff 500 https://github.com/owner/repo/pull/456
```

**Pipe to a file for later viewing:**
```bash
gh view-md https://github.com/owner/repo/issues/123 > issue-123.md
```

**Pipe to an LLM for analysis:**
```bash
gh view-md https://github.com/owner/repo/pull/456 | llm "Summarize this PR"
```

## Features

### Comprehensive Content Rendering
- **Issue/PR metadata**: Title, author, creation date, status
- **Full body content**: Original description with HTML comments stripped
- **Comments**: All comments with timestamps and author information
- **Timeline events**: Labels, assignments, milestones, state changes, etc.
- **PR-specific content**:
  - Code diffs (with size limits)
  - Review comments with file context
  - Commit history
  - CI/check status
  - Statistics (lines added/removed, files changed)

### Smart Content Processing
- **Link hydration**: Automatically converts bare GitHub issue/PR URLs to markdown links with titles
- **Image handling**: Downloads and references GitHub private images and external images locally
- **Event grouping**: Groups related timeline events (like multiple label additions) for cleaner output
- **Parallel processing**: Fetches data concurrently for faster performance

### Output Format
The script generates clean, structured markdown that includes:
- Proper headings and formatting
- Code blocks for diffs
- Timestamped entries in chronological order
- Emoji icons for different event types (🏷️ for labels, 👤 for assignments, etc.)
- Links back to original GitHub content

## Technical Details

The script creates a temporary directory structure at `/tmp/gh_issue/` to store downloaded images and maintains local references to them in the generated markdown.

For pull requests with large diffs (exceeding the `--max-diff` threshold), only filenames are shown instead of full diffs to keep the output manageable.

## Use Cases

- **LLM Analysis**: Perfect for feeding GitHub discussions to AI tools for summarization or analysis
- **Documentation**: Create offline copies of important issues/PRs
- **Reporting**: Generate markdown reports that can be converted to other formats
- **Review Preparation**: Get a complete view of a PR before review meetings

## License

This project follows standard open source practices. Check the repository for specific license information.
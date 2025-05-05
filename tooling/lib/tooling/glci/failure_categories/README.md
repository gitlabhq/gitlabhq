# CI/CD Failure Categories

## Overview

The CI/CD Failure Categories system is a toolset for automatically analyzing CI job failures, categorizing them based on patterns in job logs, and reporting these categories through internal events. This enables better tracking, debugging, and resolution of CI pipeline failures.

## Architecture

The system consists of three main components:

1. **DownloadJobTrace** - Downloads the job trace (log) from the GitLab API
2. **JobTraceToFailureCategory** - Analyzes the trace to determine the failure category based on pattern matching
3. **ReportJobFailure** - Reports the failure category via internal events for tracking and analysis

These components are orchestrated by the `FailureAnalyzer` class which handles the end-to-end process.

## Failure Categories

The system recognizes a wide range of failure categories organized into three types of pattern matching:

- **Single-line patterns** ([single_line_patterns.yml](patterns/single_line_patterns.yml)) - Matches failures found on a single line
- **Multi-line patterns** ([multiline_patterns.yml](patterns/multiline_patterns.yml)) - Matches failures that require detecting multiple patterns across different lines
- **Catchall patterns** ([catchall_patterns.yml](patterns/catchall_patterns.yml)) - Used as fallbacks when more specific patterns don't match

Each category contains:
- A descriptive name
- A detailed description of what the failure means
- One or more regex patterns to match in job logs

## Usage

### Command Line

```bash
# Add the `failure category analysis (fca)` to your .bashrc/.zshrc:
alias fca='PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE="${GITLAB_API_PRIVATE_TOKEN}" ~/src/gdk/gitlab/tooling/lib/tooling/glci/local_batch_failure_analyzer.rb'

# Analyze a single job by URL
fca https://gitlab.com/gitlab-org/gitlab/-/jobs/12345

# Analyze multiple jobs from a CSV file
fca --csv failed_jobs.csv
```

The CSV file should have the following format:
```
CREATED_AT,JOB_URL
2025-04-30T00:29:26.195478Z,https://gitlab.com/gitlab-org/gitlab/-/jobs/12345
2025-04-30T00:29:26.04171Z,https://gitlab.com/gitlab-org/gitlab/-/jobs/12346
```

You can also use the individual scripts directly:

```bash
# Analyze a single job
./tooling/lib/tooling/glci/failure_analyzer.rb <job_id>

# Local batch processing for multiple jobs
./tooling/lib/tooling/glci/local_batch_failure_analyzer.rb <job_url>

# Batch processing with a CSV file
./tooling/lib/tooling/glci/local_batch_failure_analyzer.rb --csv <csv_file_path>
```

### Required Environment Variables

When used within GitLab CI, these environment variables are typically available automatically:

```
CI_API_V4_URL
CI_PROJECT_ID
CI_JOB_ID
PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE
CI_JOB_STATUS
```

For local usage, you'll need to set these manually (see script headers for examples).

## Extending the System

### Adding New Failure Categories

1. Identify patterns in CI job logs that indicate specific types of failures
2. Add these patterns to the appropriate YAML file:
   - For single-line patterns: `single_line_patterns.yml`
   - For multi-line patterns: `multiline_patterns.yml`
   - For catchall patterns: `catchall_patterns.yml`
3. Follow the existing format:
   ```yaml
   failure_categories:
     category_name:
       description: "Detailed description of this failure type"
       patterns:
         - "regex pattern 1"
         - "regex pattern 2"
   ```
4. The order of categories matters! Patterns are matched from top to bottom.

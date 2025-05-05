# Failure Category Reference

[[_TOC_]]

## apollo

**Description**: Issues with Apollo GraphQL client configuration or operation, used for frontend GraphQL interactions.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Loading Apollo Project`

**Causes**:
- Apollo GraphQL client misconfiguration
- Schema synchronization issues
- Network problems when fetching GraphQL schema
- Incompatible Apollo client versions
- GraphQL query validation errors

**Solutions**:
- Check Apollo client configuration
- Re-generate local GraphQL schema files
- Verify network connectivity to GraphQL endpoints
- Update Apollo client dependencies if needed
- Validate GraphQL queries against the schema

## artifacts_not_found_404

**Description**: CI/CD artifacts not found (HTTP 404 errors), typically when trying to download artifacts from previous jobs that don't exist.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Downloading artifacts from coordinator... not found`

**Causes**:
- Artifacts expired or were never created
- Job reference incorrect or doesn't exist
- Permissions issue accessing artifacts
- Artifacts were purged or manually deleted
- Job didn't complete successfully to generate artifacts

**Solutions**:
- Verify the referenced job exists and completed successfully
- Check artifact expiration settings
- Ensure correct job and project references for artifacts
- Verify permissions to access artifacts
- For missing dependencies, check if jobs are properly linked
- Regenerate artifacts by re-running upstream jobs if needed

## artifacts_upload_502

**Description**: Bad Gateway errors (HTTP 502) during CI/CD artifact uploads, typically due to network or server issues.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Uploading artifacts .+ 502 Bad Gateway`

**Causes**:
- GitLab artifact storage service issues
- Network problems during upload
- Large artifacts timing out during transfer
- Load balancer or proxy problems
- Temporary service degradation

**Solutions**:
- Retry the job after a delay
- Reduce artifact size if possible
- Split large artifacts into smaller ones
- Check GitLab status page for ongoing issues
- Verify network stability between runner and GitLab
- For persistent issues, report to GitLab support

## as_if_foss_git_push_issues

**Description**: Git push failures in the as-if-FOSS pipeline, which creates a mirror of the GitLab codebase without EE-specific code.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `failed to push some refs to 'https://gitlab.com/gitlab-org/gitlab-foss.git'`

**Causes**:
- Authentication or permission issues with the target repository
- Force push required but not specified
- Target branch protected from pushes
- Remote repository rejecting changes
- Concurrent modifications to target repository

**Solutions**:
- Check authentication tokens and permissions for the target repository
- Verify CI user has push access to the target repository
- For non-fast-forward updates, use force push if appropriate
- Check target repository branch protection rules
- Ensure target repository is not in a locked state
- Retry the job after resolving concurrent modification conflicts

## assets_compilation

**Description**: Failures during frontend asset compilation with webpack, used to bundle JavaScript, CSS, and other assets.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Error: Unable to compile webpack production bundle`

**Causes**:
- JavaScript syntax errors
- Missing dependencies or incorrect versions
- Webpack configuration issues
- Memory constraints during compilation
- Incompatible module formats or imports

**Solutions**:
- Check JavaScript files for syntax errors
- Verify all dependencies are installed and compatible
- Review webpack configuration for issues
- Run compilation locally to debug with more detailed output
- For memory issues, increase available memory or optimize build
- Check for circular dependencies or other module issues

## authentication_failures

**Description**: Authentication failures when accessing protected resources, including Git repositories, Docker registries, or API endpoints. Usually due to invalid credentials, expired tokens, or insufficient permissions.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `fatal: Authentication failed for`
- `HTTP Basic: Access denied`

**Causes**:
- Invalid credentials (username/password or token)
- Expired access tokens
- Insufficient permissions for the requested operation
- Authentication method not supported or incorrect
- Two-factor authentication required but not provided
- Token revoked or invalidated

**Solutions**:
- Verify credentials are correct and not expired
- Check if token has necessary permissions
- Generate a new token if current one might be invalid
- Ensure CI/CD variables are properly set and masked
- Verify the authentication method is supported
- Check organization access policies that might restrict access

## bao_linux_checksum_mismatch

**Description**: Checksum verification failures for the bao-linux-amd64 binary, used for OpenBao secrets management in GitLab.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ERROR: Checksum mismatch for \`bao-linux-amd64\``

**Causes**:
- Binary download corruption or truncation
- Expected checksum out of date
- Wrong binary version downloaded
- Intentional binary modifications
- Network issues during download

**Solutions**:
- Clear cached binaries and retry download
- Update expected checksum if using a new version
- Verify download source is correct
- Check for network proxy or firewall issues
- Manually download and verify the binary
- Report issue if persistent across multiple attempts

## build_gdk_image

**Description**: Failures during GitLab Development Kit image building, used for local development environments.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Building GDK image`

**Causes**:
- Docker build process errors
- Missing dependencies for GDK image
- Resource constraints during build
- Incompatible base image or operating system
- Network issues when fetching dependencies

**Solutions**:
- Check specific error details in the build output
- Ensure Docker has sufficient resources allocated
- Verify network connectivity for dependency fetching
- Check for incompatible software versions
- Review GDK image build documentation for requirements
- Update Docker and related tools if needed

## build_qa_image

**Description**: Failures during QA image building, used for end-to-end testing of GitLab.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Building QA image for`

**Causes**:
- Docker build errors for QA image
- Missing or incompatible dependencies
- Network connectivity issues during build
- Resource constraints (memory, disk space)
- Version incompatibilities in dependencies

**Solutions**:
- Check Docker build logs for specific errors
- Ensure sufficient resources for image building
- Verify network connectivity for dependency downloads
- Update dependency versions in Dockerfile if needed
- Follow QA image build documentation for requirements
- Consider building locally to debug issues

## cells_lint

**Description**: Linting failures in Cells-related code and configuration, particularly around application settings definition files.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `scripts/cells/ci-ensure-application-settings-have-definition-file.rb`

**Causes**:
- Missing definition files for application settings
- Inconsistencies between settings and definitions
- Improper formatting of settings definition files
- Changes to application settings without updating definitions
- Cells architecture violations

**Solutions**:
- Create missing definition files for application settings
- Ensure definition files match actual application settings
- Follow the Cells architecture guidelines
- Check for proper YAML formatting in definition files
- Refer to existing definition files for examples of correct structure

## cng

**Description**: Cloud Native GitLab container image issues, affecting containerized GitLab deployments and related tools.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `=== block '.+' error ===`
- `failed to load command: orchestrator`

**Causes**:
- Container build process failures
- Dependency issues in Cloud Native GitLab images
- Configuration errors in CNG components
- Resource constraints during containerization
- Incompatible component versions

**Solutions**:
- Check specific block error messages for details
- Verify dependencies are correctly specified
- Review CNG component configuration
- Ensure sufficient resources for container builds
- Update component versions to compatible releases
- Refer to CNG documentation for troubleshooting

## could_not_curl

**Description**: Failures when using curl to make HTTP requests, typically due to network issues, invalid URLs, or server errors. Often includes HTTP error codes that provide more specific information.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `curl.+The requested URL returned error`

**Causes**:
- Network connectivity issues
- Server returning HTTP error codes
- Invalid or malformed URLs
- DNS resolution failures
- Timeouts due to slow server response
- Server-side issues or maintenance

**Solutions**:
- Check URL format and validity
- Verify network connectivity to the target server
- Look at the specific HTTP error code for more details
- For authentication errors, verify credentials
- Add retry logic with backoff for transient issues
- Check if the server or service is experiencing known issues

## danger

**Description**: Failures in the Danger code review tool, which automatically checks merge requests for common issues.

**Source File**: `multiline_patterns.yml`

**Patterns**:
- `DANGER_GITLAB_API_TOKEN,Errors:`

**Causes**:
- Commit message format doesn't follow guidelines (too long, missing reference, etc.)
- Missing changelog entry when one is required
- Documentation updates required but missing
- Database migration rules not followed
- Merge request is too large (exceeds recommended changes)
- Missing labels required for certain types of changes

**Solutions**:
- Review specific errors in the Danger output to identify what needs to be fixed
- Fix commit messages to follow guidelines: https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#commit-messages-guidelines
- Add a changelog entry in the correct format and location
- Update documentation to reflect code changes
- Consider splitting large merge requests into smaller, focused changes
- Add required labels based on the type of change being made
- Run the danger-review job again after making changes

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `If needed, you can retry the.+\`danger-review\` job`

**Causes**:
- Temporary failure in Danger analysis
- Network or API connectivity issues during analysis
- Timeout or resource constraints during review
- GitLab API rate limiting
- Errors in Danger configuration

**Solutions**:
- Retry the danger-review job as suggested in the error message
- Check specific errors in the job output to identify underlying issues
- If persistent, verify Danger configuration is correct
- Make sure necessary CI variables are properly set
- For repeated failures, try pushing a new commit to trigger a fresh analysis

## db_connection_in_rails_initializer

**Description**: Database connections being made during Rails initializers, which is discouraged as it can cause race conditions and other issues during application startup.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `raise_database_connection_made_error`

**Causes**:
- Database queries or connections made during Rails initialization
- ActiveRecord model loading or queries in initializers
- Running migrations or schema operations during startup
- Eager loading models that trigger database access
- Cache warming or configuration that connects to database too early

**Solutions**:
- Move database operations out of initializers
- Use lazy loading for database-dependent components
- Defer database connections until after application boot
- Check initializer code for explicit or implicit database access
- For necessary database access in initialization, see documentation: https://docs.gitlab.com/ee/development/rails_initializers.html#database-connections-in-initializers

## db_cross_schema_access

**Description**: Unauthorized cross-schema database access attempts, which occur when code tries to access tables outside the allowed schemas for the current database connection.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection::CrossSchemaAccessError`

**Causes**:
- Using a connection to access tables outside its allowed schema scope
- Incorrect connection routing for database operations
- Missing proper connection switching in multi-database operations
- Query accessing tables across different database partitions
- ORM configuration not respecting schema boundaries

**Solutions**:
- Use the appropriate connection for the specific schema (main vs CI)
- Wrap cross-schema queries in the correct connection context
- Review GitLab's database architecture documentation
- For CI-related tables, use Ci::ApplicationRecord instead of ApplicationRecord
- Consider refactoring to avoid cross-schema access altogether
- Check connection routing using ApplicationRecord.connection.select_value('SELECT current_schema')

## db_migrations

**Description**: Database migration failures, including schema inconsistencies, rollback issues, pending migrations, and column operation errors. These issues often occur when database changes aren't properly synchronized.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Error: rollback of added migrations does not revert db/structure.sql to previous state, please investigate`
- `the committed db/structure.sql does not match the one generated by running added migrations`
- `the committed files in db/schema_migrations do not match those expected by the added migrations`
- `You have.+pending migrations`
- `Column operations, like dropping, renaming or primary key conversion`
- `createdb: error:`
- `Batched migration should be finalized only after at-least one required stop from queuing it`

**Causes**:
- Migration files and db/structure.sql are out of sync
- Migrations are not properly reversible
- Migration has been added but not applied locally
- Column operations missing the required ignore_columns in the model
- Database already exists when trying to create it
- Batched migration finalized too early

**Solutions**:
- Run `bin/rails db:migrate db:test:prepare` locally
- Ensure your migrations are properly reversible by testing them with `bin/rails db:rollback`
- For column operations, add `self.ignored_columns = [:column_name]` to the model before dropping
- Follow the batched migrations workflow: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#finalize-a-batched-background-migration
- Add the 'pipeline:skip-check-migrations' label to skip this check if needed
- Check if database exists before attempting to create it

## db_table_write_protected

**Description**: Attempts to write to database tables that are protected within the GitLab database schema, or unsupported cross-joins between database tables. This usually happens when code tries to modify tables it shouldn't have access to.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Table.+is write protected within this Gitlab database`
- `Unsupported cross-join across`

**Causes**:
- Accessing database tables outside allowed schemas
- Cross-schema joins involving tables that should be separated
- Using wrong database connection for specific operations
- Database query violating database partition rules
- Not respecting the database architecture constraints

**Solutions**:
- Ensure you're using the correct database connection for the operation
- Check the documentation on multiple databases: https://docs.gitlab.com/ee/development/database/multiple_databases.html
- Refactor code to avoid cross-schema joins and respect database boundaries
- For CI data, use the CI database connection context
- Consider using proper abstractions or services to access cross-schema data

## dependency-scanning_permission_denied

**Description**: Permission issues during dependency scanning, where the scanner cannot access files due to insufficient permissions.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `\[FATA\] \[dependency-scanning\].+ permission denied`

**Causes**:
- Scanner running with insufficient permissions
- File or directory permission issues
- Docker volume mount permission problems
- Restrictive umask settings
- Protected files or directories

**Solutions**:
- Check file permissions in the project directory
- Ensure Docker volume mounts have correct permissions
- Verify the scanner is running with appropriate user privileges
- Adjust umask settings if needed
- For Docker-based scanners, check container user configuration
- Consider adding permission checks to pre-scan steps

## docs_deprecations_outdated

**Description**: Outdated documentation about deprecated features that needs to be updated to reflect current deprecation status.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ERROR: Deprecations documentation is outdated`

**Causes**:
- New deprecations not documented
- Deprecated features removed but still listed in docs
- Deprecation timeframe changed but not updated in docs
- Inconsistencies between code deprecations and documentation
- Deprecation documentation format not followed

**Solutions**:
- Run command suggested in the error to update deprecation docs
- Add documentation for new deprecated features
- Remove documentation for removed deprecated features
- Update deprecation timeframes in documentation
- Follow deprecation documentation guidelines
- Ensure deprecation notices match actual code status

## docs_lint_failed

**Description**: Documentation linting failures, including formatting issues, broken links, and other quality checks for GitLab's documentation.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ERROR: lint test\(s\) failed.+Review the log carefully to see full listing`
- `files inspected,.+lints? detected`
- `Issues found in .+input.+Find details below.`
- `scripts/lint-docs-redirects.rb`
- `git diff --exit-code db/docs`

**Causes**:
- Markdown formatting errors
- Broken links in documentation
- Style guide violations in docs
- Invalid redirects in documentation
- Inconsistent formatting or structure
- Missing required sections in documentation

**Solutions**:
- Run documentation linting locally: `bundle exec rake gitlab:docs:lint`
- Fix formatting according to style guide
- Update or remove broken links
- Check redirects with `scripts/lint-docs-redirects.rb`
- Follow documentation structure guidelines
- Address specific issues highlighted in the linting output

## docs_outdated

**Description**: Outdated documentation that needs to be regenerated, typically seen when code changes affect documented features or APIs.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `documentation is outdated.+Please update it by running`

**Causes**:
- Code changes affecting documented APIs or features
- Schema changes not reflected in documentation
- Auto-generated docs not updated after changes
- Documentation dependencies out of sync
- API changes without corresponding doc updates

**Solutions**:
- Run the command provided in the error message to update docs
- Ensure documentation is updated when code changes
- Follow the documentation process for API changes
- Regenerate schema-dependent documentation
- Review and test documentation changes for accuracy

## docker_not_running

**Description**: Issues where the Docker daemon is not running or is unavailable, preventing container operations.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Is the docker daemon running`

**Causes**:
- Docker service not running on runner
- Docker socket not accessible
- Permission issues accessing Docker
- Docker configuration problems
- Resource exhaustion preventing Docker operations

**Solutions**:
- Ensure Docker service is running
- Check Docker socket permissions
- Verify user has permission to access Docker
- Restart Docker service if possible
- Check Docker logs for specific errors
- For runners, ensure Docker is properly configured

## e2e_lint

**Description**: Linting issues in end-to-end tests, particularly related to testcase linking conventions that ensure proper documentation and traceability for tests.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Testcase link violations detected`

**Causes**:
- Missing testcase links in E2E test files
- Incorrect format for testcase links
- Links pointing to non-existent testcases
- Multiple E2E tests referencing the same testcase
- Outdated testcase references

**Solutions**:
- Add proper testcase links to E2E test files using correct format
- Verify testcase links point to valid, existing cases
- Ensure each test has a unique testcase reference
- Update outdated testcase references
- Follow E2E test documentation guidelines

## e2e_specs

**Description**: End-to-end test failures specific to GitLab's QA framework, including failures to load the QA tools, failed readiness checks, or other issues with the end-to-end testing infrastructure.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `failed to load command: bin/qa`
- `failed to load command: gitlab-qa`
- `QA::Tools::ReadinessCheck::ReadinessCheckError`

**Causes**:
- QA framework not properly installed or initialized
- Dependencies missing for QA tests
- Environment not properly set up for E2E testing
- Target instance not ready or accessible
- Issues with test environment configuration

**Solutions**:
- Ensure QA dependencies are properly installed
- Check QA framework initialization and configuration
- Verify target GitLab instance is accessible and responsive
- Review readiness check logs to identify specific failures
- Check for recent changes to QA framework or test environment
- Run setup steps manually to debug environment issues

## error_in_db_migration

**Description**: General errors occurring during database migrations that cause the migration and all subsequent migrations to be canceled.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `An error has occurred, this and all later migrations canceled`
- `An error has occurred, all later migrations canceled`

**Causes**:
- SQL syntax errors in migrations
- Referenced database objects don't exist
- Schema inconsistencies between environments
- Incomplete or incorrect migration logic
- Dependent migrations not executed first

**Solutions**:
- Check migration SQL syntax and logic
- Verify all referenced database objects exist
- Ensure migrations run in the correct order
- Test migrations thoroughly in development before committing
- Add more specific error handling in migrations
- Review database state manually to identify inconsistencies

## eslint

**Description**: JavaScript code style and quality issues detected by ESLint, the JavaScript linter used in GitLab's frontend development.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `node scripts/frontend/eslint.js . --format gitlab`
- `Running ESLint with the following rules enabled`

**Causes**:
- JavaScript code not following style guidelines
- Missing semicolons, improper formatting, or syntax issues
- Use of deprecated or disallowed JavaScript patterns
- Accessibility (a11y) violations in code
- Unused variables or imports

**Solutions**:
- Run ESLint locally to identify and fix issues: `yarn run lint:eslint`
- Consider using `yarn run lint:eslint:fix` to automatically fix simple issues
- Review ESLint errors and update code to follow style guidelines
- Address specific rule violations mentioned in the error output
- Check GitLab's frontend development guidelines
- For persistent issues, consider ESLint configuration adjustments

## failed_to_open_tcp_connection

**Description**: Failures to establish TCP network connections, typically due to network issues, firewalls, incorrect hostnames/IPs, or services not running on the expected ports.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Error: Failed to open TCP connection to `

**Causes**:
- Target service not running or listening on expected port
- Network connectivity issues
- Firewall blocking connection
- DNS resolution failures
- Incorrect hostname or IP address
- Service overloaded and rejecting connections

**Solutions**:
- Verify the service is running on the target host and port
- Check network connectivity between client and server
- Verify hostname resolves to the correct IP address
- Check firewall rules to ensure connection is allowed
- Try an alternative endpoint if available
- Add retry logic with exponential backoff

## failed_to_pull_image

**Description**: Docker image pull failures in CI/CD, where container images cannot be downloaded from the registry.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ERROR: Job failed: failed to pull image`

**Causes**:
- Docker registry unavailable or unreachable
- Authentication issues with registry
- Image does not exist or wrong tag specified
- Network connectivity problems
- Rate limiting on registry pulls

**Solutions**:
- Verify image name and tag are correct
- Check authentication credentials for private registries
- Ensure network connectivity to the registry
- For rate limiting, use authenticated pulls or reduce frequency
- Use image mirroring for frequently used images
- Check registry status for outages

## feature_flag_usage_check_failure

**Description**: Feature flag usage check failures, where feature flags are not properly defined or used.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Feature flag usage check failed`

**Causes**:
- Feature flags used without proper definition
- Missing or incorrect feature flag declaration
- Inconsistent feature flag usage
- Feature flag name typos or mismatches
- Not following feature flag usage guidelines

**Solutions**:
- Add proper feature flag definition files
- Ensure feature flags are declared correctly
- Fix inconsistencies in feature flag usage
- Check for typos in feature flag names
- Follow feature flag usage guidelines
- Review feature flag deprecation process if removing flags

## frontend_lockfile

**Description**: Issues with frontend dependency lockfiles, including Yarn lockfile inconsistencies that need to be resolved.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Found problems with the lockfile`
- `Your lockfile needs to be updated, but yarn was run with`

**Causes**:
- Yarn lockfile out of sync with package.json
- Running yarn with --frozen-lockfile when changes are needed
- Dependency version conflicts
- Manual edits to lockfile
- Different yarn versions between developers and CI

**Solutions**:
- Run `yarn install` without --frozen-lockfile to update lockfile
- Resolve dependency conflicts in package.json
- Avoid manual edits to yarn.lock
- Use consistent yarn versions across environments
- For CI issues, update lockfile locally and commit changes
- Consider running yarn dedupe to fix duplicate packages

## gemnasium-python-dependency_scanning

**Description**: Failures in Python dependency scanning with Gemnasium, typically related to pipenv sync issues in dependency scanning jobs.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `running /usr/local/bin/pipenv sync .+: exit status 1`
- `\[gemnasium-python\] .+ pipenv sync failed`

**Causes**:
- Python dependency conflicts
- Missing or incompatible Python version
- Pipenv lock file inconsistencies
- Network issues during dependency resolution
- Resource constraints during installation

**Solutions**:
- Update Pipfile.lock using `pipenv lock`
- Resolve dependency conflicts in Pipfile
- Ensure correct Python version is available
- Check for private packages requiring authentication
- Verify all dependencies are accessible in CI environment
- For persistent issues, try recreating the virtual environment

## gems_build

**Description**: Failures during gem native extension building, which often occur with gems that have C extensions that fail to compile.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Gem::Ext::BuildError: ERROR: Failed to build gem native extension.`

**Causes**:
- Missing build dependencies (compilers, libraries)
- Incompatible C library versions
- Platform-specific build issues
- Header files missing for required libraries
- System resource constraints during compilation

**Solutions**:
- Install required build dependencies
- For PostgreSQL-related gems, install libpq-dev or equivalent
- For nokogiri, ensure libxml2-dev and other dependencies are available
- Check for specific compilation errors in the build output
- Use pre-compiled gems when available
- Consult gem-specific documentation for build requirements

## gems_not_found

**Description**: Missing Ruby gems required by the application, which can happen when dependencies aren't properly installed or configured.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Bundler::GemNotFound`

**Causes**:
- Gem listed in Gemfile but not installed
- Gem source unavailable or unreachable
- Version constraints that cannot be satisfied
- Network issues during gem installation
- Platform-specific gems missing on current platform

**Solutions**:
- Run `bundle install` to install missing gems
- Check gem source availability and connectivity
- Review version constraints for feasibility
- For platform-specific issues, specify platform in Gemfile
- Check for typos in gem names
- Verify gem exists in specified sources

## gemfile_issues

**Description**: Issues with Ruby gem dependencies and Gemfile lockfiles, including outdated dependencies, checksum mismatches, and conflicting gems.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `changed, but the lockfile can't be updated`
- `Your lockfile does not satisfy dependencies of`
- `contains outdated dependencies`
- `You have already activated`
- `but your Gemfile requires`
- `\(r-\)generate Gemfile.checksum with`
- `Bundler cannot continue installing`
- `Cached checksum for .+ not found`

**Causes**:
- Gemfile and Gemfile.lock out of sync
- Dependency conflicts between gems
- Outdated gems or version constraints
- Checksum verification failures
- Inconsistent gem environment between development and CI
- Manual edits to Gemfile.lock

**Solutions**:
- Run `bundle install` to update Gemfile.lock
- Generate or update checksums with `bundle exec bundler-checksum init`
- Resolve dependency conflicts by updating gem versions
- Check for version constraint issues in Gemfile
- For frozen bundle issues, run without --frozen flag
- Update outdated gems to compatible versions
- Follow Gemfile best practices in GitLab documentation

## git_issues

**Description**: Git repository and version control related failures, including cloning issues, reference problems, and connectivity errors.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `cloning repository: exit status 128`
- `did not match any file\(s\) known to git`
- `fatal: couldn't find remote ref`
- `fatal: expected flush after ref listing`
- `fatal: fetch-pack: invalid index-pack output`
- `fatal: Not a valid object name`
- `fatal: protocol error: bad pack header`
- `fatal: the remote end hung up unexpectedly`
- `TimeoutExpired: Command '\['git', 'fetch'`

**Causes**:
- Network connectivity issues to Git repositories
- Invalid or non-existent Git references (branches, tags)
- Large repository transfer issues
- Authentication or permission problems
- Git protocol errors or incompatibilities
- Repository corruption or inconsistency

**Solutions**:
- Check network connectivity to Git servers
- Verify branch, tag, or commit references exist
- Ensure authentication credentials are correct
- For large repositories, try shallow cloning
- Check for Git version compatibility issues
- Try with increased Git buffer sizes or timeouts
- For reference errors, verify the branch or tag exists

## gitaly_spawn_failed

**Description**: Failures in spawning Gitaly service processes, which handle Git operations in GitLab.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `gitaly spawn failed`

**Causes**:
- Gitaly binary missing or incorrect permissions
- Configuration issues for Gitaly service
- Resource constraints preventing process spawn
- Port conflicts or availability issues
- Dependencies required by Gitaly not available

**Solutions**:
- Check Gitaly binary existence and permissions
- Verify Gitaly configuration is correct
- Ensure required ports are available
- Check system resource availability (memory, file descriptors)
- Review Gitaly logs for specific startup errors
- Verify all Gitaly dependencies are installed

## gitlab_too_much_load

**Description**: Situations where GitLab instance is under excessive load and unable to handle requests, typically seen in pipeline or API interactions.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `GitLab is currently unable to handle this request due to load.`

**Causes**:
- High server load or resource exhaustion
- Insufficient resources allocated to GitLab instance
- Database performance issues under load
- Background job backlogs creating contention
- Traffic spikes exceeding capacity

**Solutions**:
- Retry the operation after a delay
- Check GitLab instance health and resource usage
- Monitor for sustained high load conditions
- Consider scaling resources if consistently overloaded
- Look for inefficient queries or operations during peak load
- Implement rate limiting or traffic shaping if needed

## gitlab_unavailable

**Description**: Situations where GitLab instance is unavailable or unresponsive, preventing API requests or Git operations.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `The requested URL returned error: 500`
- `GitLab is not responding`
- `fatal: unable to access 'https://gitlab.com`

**Causes**:
- GitLab service outage or maintenance
- Network connectivity issues
- Server errors in the GitLab application
- Rate limiting or temporary access restrictions
- DNS resolution problems

**Solutions**:
- Check GitLab status page for known outages
- Verify network connectivity to GitLab servers
- Retry operations after a delay
- Check for rate limiting or access restrictions
- Verify DNS resolution is working correctly
- For persistent issues, contact GitLab support

## graphql_lint

**Description**: GraphQL schema validation and linting errors, including outdated schema files that need to be regenerated or queries that fail validation.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `needs to be regenerated, please run:`
- `GraphQL quer.+out of.+failed validation:`

**Causes**:
- GraphQL schema files out of sync with actual schema
- Invalid GraphQL query syntax
- Schema changes not reflected in generated files
- Client-side queries using fields or types that don't exist
- Modifications to GraphQL schema without updating definitions

**Solutions**:
- Run the command suggested in the error message to regenerate schema files
- Fix invalid GraphQL queries based on validation errors
- Update client queries after schema changes
- Check GraphQL schema changes for backward compatibility
- Run GraphQL validation before committing changes
- Use GraphQL sandbox to verify query validity

## http

**Description**: HTTP-related errors when making web requests, including client errors (4xx), server errors (5xx), and exceptions in HTTP client libraries. These indicate problems with API interactions or web service communications.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Server responded with code`
- `400 Bad Request`
- `503 Service Unavailable`
- `Net::HTTPClientException`
- `Net::HTTPFatalError`

**Causes**:
- Invalid request format or parameters (4xx errors)
- Server-side issues or maintenance (5xx errors)
- Authentication or authorization failures
- Rate limiting or quota exceeded
- Network connectivity problems
- Server overload or unavailability

**Solutions**:
- Check request format, parameters, and headers
- Verify authentication credentials and tokens
- For 5xx errors, wait and retry with exponential backoff
- Look for service status updates if persistent server errors
- Check API documentation for correct request format
- Implement circuit breakers for unreliable services

## http_500

**Description**: HTTP 500 Internal Server errors when interacting with web services, indicating server-side problems.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `500 Internal Server Error`

**Causes**:
- Server-side application errors
- Database connectivity or query issues
- Resource exhaustion on server
- Unhandled exceptions in server code
- Infrastructure or deployment problems

**Solutions**:
- Check server logs for detailed error information
- Verify server dependencies are available and working
- For GitLab API issues, check GitLab instance health
- Retry operations after a delay for transient issues
- Reduce request complexity or payload size if applicable
- Report persistent server errors to service maintainers

## http_502

**Description**: HTTP 502 Bad Gateway errors when interacting with web services, indicating proxy or intermediate server issues.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `502 Server Error`
- `502 \"Bad Gateway\"`
- `status code: 502`

**Causes**:
- Load balancer or proxy issues
- Backend service unavailable or timing out
- Network connectivity problems between servers
- Server overload or resource exhaustion
- Misconfiguration in proxy or gateway

**Solutions**:
- Retry the request after a delay
- Check service status for outages
- Verify network connectivity between services
- For GitLab.com issues, check status page
- Reduce request complexity or frequency
- If persistent, report to infrastructure team

## io

**Description**: Input/Output errors during file operations, network transfers, or device interactions. These indicate low-level problems with reading from or writing to resources.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `ERROR: .+ IO ERROR`

**Causes**:
- Disk or storage device failures
- Network interruptions during data transfer
- File system corruption
- Insufficient permissions for I/O operations
- Resource contention or locks preventing access

**Solutions**:
- Check storage system health and available space
- Verify network connectivity for remote resources
- Ensure correct permissions for files and directories
- Add retry logic for transient I/O errors
- For CI runners, check if there are infrastructure issues

## jest

**Description**: JavaScript test failures in Jest framework, which is used for testing GitLab's frontend components.

**Source File**: `multiline_patterns.yml`

**Patterns**:
- `Ran all test suites,Command failed with exit code 1`
- `Ran all test suites,exited with status 1`

**Causes**:
- JavaScript component doesn't match test expectations
- Snapshot tests are outdated after UI changes
- JavaScript syntax errors or runtime errors
- Mocked services or components not properly set up
- Tests timeout due to asynchronous operations not resolving
- Vue component lifecycle issues (especially with Vue 3 compatibility)

**Solutions**:
- Run the specific failing test locally: `yarn jest <test_file> -t '<test_name>'`
- Update snapshots if UI has intentionally changed: `yarn jest -u <test_file>`
- Check for JavaScript syntax errors or missing dependencies
- Ensure mocks are properly set up and cleaned up between tests
- Add proper async/await handling for asynchronous operations
- For Vue 3 compatibility issues, check the Vue migration guide for breaking changes

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Command .+ node_modules/.bin/jest.+ exited with status 1`

**Causes**:
- JavaScript test failures
- Test environment setup issues
- Syntax errors in test code
- Missing or incompatible dependencies
- Test timeouts or performance issues

**Solutions**:
- Run the specific failing test locally to debug
- Check test logs for specific failure details
- Update test snapshots if UI has changed intentionally
- Verify all dependencies are installed correctly
- For timeout issues, increase test timeout limits
- Check for Vue compatibility issues if using Vue components

## job_timeouts

**Description**: CI/CD job execution timeouts, occurring when jobs run longer than their configured time limits (often 90 minutes for GitLab CI). These may indicate infinite loops, performance issues, or jobs that simply need more time.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `execution took longer than 1h30m0s seconds`

**Causes**:
- Tests or operations taking longer than the job timeout limit
- Infinite loops or deadlocks
- Resource contention slowing down execution
- Inefficient code or database queries
- Large data sets being processed without optimization

**Solutions**:
- Optimize slow-running tests or operations
- Split long-running jobs into multiple smaller jobs
- Use parallelization to speed up test execution
- Fix infinite loops or deadlocks in the code
- Consider increasing job timeout if appropriate
- Add timeouts to potentially long-running operations

## kubernetes

**Description**: Kubernetes cluster connectivity or operation issues, affecting containerized deployments and tests.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Error: Kubernetes cluster unreachable`

**Causes**:
- Kubernetes API server unavailable
- Authentication or authorization issues
- Network connectivity problems
- Misconfiguration of cluster access
- Certificate or TLS issues

**Solutions**:
- Verify Kubernetes cluster is running and healthy
- Check authentication credentials and certificates
- Test connectivity to Kubernetes API endpoint
- Ensure proper RBAC permissions for operations
- Check for network policy or firewall restrictions
- Verify kubeconfig is correctly configured

## logs_too_big_to_analyze

**Description**: Log output exceeded size limits for complete analysis, truncating job logs and potentially hiding important information.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Job execution will continue but no more output will be collected`

**Causes**:
- Excessive log output from tests or processes
- Debug logging enabled in verbose mode
- Infinite loops or excessive repetition in logs
- Large data dumps to standard output
- Log size exceeding GitLab CI limits

**Solutions**:
- Reduce log verbosity in tests and processes
- Avoid printing large data structures to output
- Fix any loops or repetitive logging
- Use log files for detailed logs instead of stdout
- Add filtering or sampling for high-volume logs
- Split jobs that produce excessive logs

## makefile

**Description**: Failures in Makefile-based build processes, often occurring during compilation of C/C++ code, GitLab components like Gitaly, or when running make-based commands. The Error 1 indicates a non-zero exit status from a command.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `make: .+ Error 1`

**Causes**:
- Compilation errors in C/C++ code
- Missing dependencies required by the build
- Command referenced in Makefile not found or returning error
- Syntax errors in Makefile
- Permission issues preventing execution

**Solutions**:
- Check compilation errors in the lines preceding this message
- Install missing dependencies required for the build
- Verify commands used in the Makefile exist and work correctly
- Check Makefile syntax and variable definitions
- Ensure proper permissions on files being built

## no_space_left

**Description**: Insufficient disk space on the CI/CD runner, causing file operations to fail due to lack of storage.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `no space left on device`
- `There was insufficient space remaining on the device`

**Causes**:
- Runner disk space exhausted
- Large artifacts or build outputs filling disk
- Inadequate cleanup between jobs
- Docker layers or images consuming space
- Log files or core dumps accumulating

**Solutions**:
- Clean up unnecessary files during build
- Reduce artifact size or split into smaller artifacts
- Add cleanup steps in before_script or after_script
- For Docker runners, prune images and volumes regularly
- Consider using runners with more disk space
- Optimize build process to use less disk space

## package_hunter

**Description**: Errors in package monitoring and tracking services, used to scan for vulnerabilities in project dependencies.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Error calling /monitor/project/`

**Causes**:
- Service API connectivity issues
- Invalid or expired authentication credentials
- Rate limiting or quota exhaustion
- Service outage or maintenance
- Incompatible project configuration

**Solutions**:
- Check connectivity to package monitoring services
- Verify authentication tokens are valid and not expired
- Look for rate limiting headers in responses
- Check service status and maintenance announcements
- Ensure project configuration is compatible with the service
- Retry scan during lower usage periods if rate limited

## pajamas_violations

**Description**: Violations of Pajamas design system requirements, GitLab's design system that ensures consistent UI components and experiences.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `blocking Pajamas violation\(s\) found.`
- `Merge request scan exit status: 2`

**Causes**:
- Using non-Pajamas UI components or styles
- Incorrect implementation of Pajamas components
- CSS/SCSS that doesn't follow design system guidelines
- Accessibility violations in UI components
- Custom styling that conflicts with Pajamas standards

**Solutions**:
- Replace custom UI components with Pajamas equivalents
- Follow Pajamas implementation guidelines
- Use Pajamas utility classes instead of custom CSS
- Address accessibility issues highlighted in the report
- Refer to Pajamas documentation: https://design.gitlab.com
- Consult with UX team for complex component needs

## pg_query_canceled

**Description**: PostgreSQL query cancellation errors in tests, typically due to long-running queries or timeout configurations.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `We have detected a PG::QueryCanceled error in the specs, so we're failing early.`

**Causes**:
- Long-running database queries hitting timeout limits
- Inefficient queries with missing indexes
- Queries operating on large datasets
- Resource contention slowing query execution
- Statement timeout configuration too restrictive

**Solutions**:
- Optimize slow queries with proper indexes
- Rewrite queries to be more efficient
- Add pagination or batching for large dataset operations
- Check for table locks or resource contention
- Review database query plans for inefficient operations
- Consider appropriate statement timeout settings for test environment

## postgresql_unavailable

**Description**: PostgreSQL database connection failures, where the database is unreachable or returns connection errors.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::ConnectionBad`

**Causes**:
- PostgreSQL server not running
- Database connectivity issues
- Authentication failures
- Resource exhaustion on database server
- Misconfigured connection parameters

**Solutions**:
- Verify PostgreSQL server is running
- Check network connectivity to database server
- Ensure database credentials are correct
- Review database server logs for specific errors
- Check resource usage on database server
- Verify database connection configuration

## psql_failed_command

**Description**: Failures when executing PostgreSQL commands directly through psql, often seen during schema loading or database initialization.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `psql:.+ERROR:`

**Causes**:
- SQL syntax errors in scripts executed by psql
- Database objects not existing when referenced
- Permissions issues for psql operations
- Connectivity problems to PostgreSQL server
- Resource constraints or locks preventing execution

**Solutions**:
- Check SQL syntax in scripts run by psql
- Verify database objects exist before referencing them
- Ensure proper permissions for database operations
- Check database connectivity and configuration
- Review PostgreSQL server logs for additional error context
- Add error handling or conditional logic in scripts

## rails_invalid_sql_statement

**Description**: Invalid SQL statements in Rails ActiveRecord operations that cannot be executed by PostgreSQL due to syntax or semantic errors.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ActiveRecord::StatementInvalid`

**Causes**:
- SQL syntax errors in queries
- Referencing non-existent tables or columns
- Type mismatches in query parameters
- Incorrect join conditions or query structure
- PostgreSQL constraints or rules violations

**Solutions**:
- Check SQL syntax in queries and migrations
- Verify referenced tables and columns exist
- Ensure parameter types match column types
- Review query structure for logical errors
- Test complex queries in development environment first
- Use database inspection tools to verify schema

## rails_pg_active_sql_transaction

**Description**: Postgres errors related to operations that cannot be performed inside a transaction block, such as creating indexes concurrently.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::ActiveSqlTransaction`

**Causes**:
- Attempting to create indexes concurrently inside a transaction
- Using operations that require being outside transactions
- Nested transactions preventing certain PostgreSQL operations
- Missing `disable_ddl_transaction!` in migrations that need it
- Operations requiring schema locks within transaction blocks

**Solutions**:
- Add `disable_ddl_transaction!` to migrations that use concurrent operations
- Move operations like CREATE INDEX CONCURRENTLY outside transaction blocks
- Split migration into multiple migrations if both transactional and non-transactional operations needed
- For migrations, refer to: https://docs.gitlab.com/ee/development/migration_style_guide.html#disable-ddl-transaction
- Check for explicit transaction blocks that may be wrapping restricted operations

## rails_pg_check_violation

**Description**: Violations of PostgreSQL check constraints on database tables, which prevent invalid data from being inserted.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::CheckViolation`

**Causes**:
- Inserting or updating data that violates check constraints
- Schema constraints not aligned with application code validations
- Missing validation in application code before database operations
- Changes to check constraints without updating affected data
- Seed data or migrations inserting invalid values

**Solutions**:
- Ensure data meets check constraint requirements before insert/update
- Align application validations with database constraints
- Update existing data to comply before adding or modifying constraints
- Check error details for specific constraint name and column information
- For complex constraints, consider implementing application-level validations

## rails_pg_dependent_objects_still_exist

**Description**: Attempts to drop database objects that have dependencies, such as constraints or references from other tables.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::DependentObjectsStillExist`

**Causes**:
- Dropping a table that has foreign keys pointing to it
- Removing a database object that other objects depend on
- Deleting a column referenced by constraints or indexes
- Incorrect order of operations in migrations
- Missing cascade option when dropping objects with dependencies

**Solutions**:
- Drop dependent objects first before removing their dependencies
- Use CASCADE option to automatically drop dependent objects (use with caution)
- Reorder migration steps to respect dependency order
- Explicitly remove foreign keys before dropping tables
- Identify dependent objects using PostgreSQL system catalogs

## rails_pg_duplicate_alias

**Description**: SQL query errors due to duplicate table aliases, typically occurring in complex queries with the same table name specified multiple times.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::DuplicateAlias`

**Causes**:
- Using the same alias for multiple tables in a query
- Auto-generated aliases colliding in complex queries
- Joins or CTEs with duplicate table references
- Query composition creating unintended alias duplicates
- ORMs generating queries with naming conflicts

**Solutions**:
- Use unique aliases for each table reference in queries
- Review complex queries for duplicate table aliases
- Ensure joins and subqueries have distinct aliases
- In ActiveRecord, use `from('table_name t1')` syntax to specify aliases
- Simplify overly complex queries that lead to naming conflicts

## rails_pg_duplicate_table

**Description**: Attempts to create tables that already exist in the database, usually during migration rollbacks that aren't properly checking for existing tables.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::DuplicateTable`

**Causes**:
- Creating a table that already exists
- Migration rollback that doesn't properly check existence
- Race conditions between parallel migrations
- Incomplete cleanup of previous migration attempts
- Missing conditional logic in migrations

**Solutions**:
- Use `create_table_if_not_exists` instead of `create_table`
- Add existence checks before table creation
- Ensure proper rollback logic in migrations
- Add proper up/down methods in reversible migrations
- For repeated failures, check database state manually and correct inconsistencies

## rails_pg_invalid_column_reference

**Description**: SQL syntax errors related to invalid column references, such as ordering by columns not in the select list in a DISTINCT query.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::InvalidColumnReference`

**Causes**:
- ORDER BY clause referencing columns not in SELECT with DISTINCT
- Referring to columns outside the current query scope
- Column aliases used in WHERE before they're defined
- Incorrect column names or typos
- PostgreSQL syntax requirements not being followed

**Solutions**:
- Ensure ORDER BY columns appear in the SELECT list when using DISTINCT
- Add missing columns to SELECT clause
- Use subqueries or CTEs to establish proper column scope
- Check for typos or invalid column references
- Restructure queries to follow PostgreSQL requirements

## rails_pg_no_foreign_key

**Description**: Missing foreign key constraints in the database schema, which can lead to data integrity issues. This typically happens during migration rollbacks or schema changes.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `has no foreign key for`

**Causes**:
- Foreign key constraint missing in database schema
- Migration rollback that doesn't properly restore foreign keys
- Inconsistent sequence of migrations affecting related tables
- Manual schema changes bypassing migrations
- Attempting to add a foreign key to a non-existent column or table

**Solutions**:
- Add missing foreign key constraints in migrations
- Ensure migration rollbacks properly restore removed foreign keys
- Review migration sequence to ensure correct order of operations
- Check that referenced tables and columns exist before adding foreign keys
- Use Rails migration methods like add_foreign_key and remove_foreign_key

## rails_pg_not_in_database_dictionary

**Description**: Tables missing from the database dictionary, which maintains metadata about database tables. New or deleted tables must be properly registered in the dictionary.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Any new or deleted tables must be added to the database dictionary`

**Causes**:
- New table created but not added to database dictionary
- Table definition removed without updating dictionary
- Incorrect schema assignment in database dictionary
- Missing or outdated YAML files in db/docs directory
- Schema changes not reflected in dictionary files

**Solutions**:
- Update the database dictionary by running `bin/rails gitlab:db:dictionary:generate`
- Add missing table definitions to appropriate files in db/docs directory
- Ensure new tables have correct gitlab_schema assignment
- Commit generated dictionary files with your changes
- See documentation: https://docs.gitlab.com/ee/development/database/database_dictionary.html

## rails_pg_sidekiq

**Description**: Sidekiq API routing errors in the database context, particularly related to unrouted Sidekiq Redis calls that should be inside a .via block.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Gitlab::SidekiqSharding::Validator::UnroutedSidekiqApiError`

**Causes**:
- Sidekiq Redis calls made outside a .via routing block
- Missing proper routing context for sharded Sidekiq operations
- Direct Sidekiq API calls bypassing the routing layer
- Missing Sidekiq client configuration
- Code not adapted for Sidekiq sharding architecture

**Solutions**:
- Wrap Sidekiq operations in appropriate .via blocks
- Use Sidekiq::Client.via instead of direct API calls
- Follow Sidekiq sharding guidelines in the documentation
- Review recent changes to Sidekiq implementation
- Check other Sidekiq-related files for correct patterns to follow

## rails_pg_undefined_column

**Description**: References to columns that don't exist in database tables, typically occurring during schema changes or mismatched migrations.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::UndefinedColumn`

**Causes**:
- Column doesn't exist in the table being queried
- Column was removed but still referenced in code
- Migration hasn't been run to add the column
- Typo in column name
- Schema changes not synchronized across environments

**Solutions**:
- Verify column exists in the database schema
- Check for typos in column names
- Run pending migrations that may add the referenced column
- Update code to match current schema after column removals
- Use database inspection tools to confirm table structure

## rails_pg_undefined_table

**Description**: References to tables that don't exist in the database, often seen during migration rollbacks or when tables are renamed/dropped.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `PG::UndefinedTable`

**Causes**:
- Table doesn't exist in the database
- Table was dropped but still referenced in code
- Migration hasn't been run to create the table
- Incorrect schema or search path
- Typo in table name

**Solutions**:
- Verify table exists in the correct schema
- Run pending migrations that create the table
- Check for typos in table names
- Ensure correct schema is being used
- Update code references after table renames or removals
- Check database schema with `\dt` in psql or database inspection tools

## rails-production-server-boot

**Description**: Rails production server boot failures, where the application server fails to start or respond to requests on expected ports.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `curl: \(7\) Failed to connect to 127.0.0.1 port 3000 after`
- `curl: \(7\) Failed to connect to 127.0.0.1 port 8080 after`

**Causes**:
- Rails server failed to start properly
- Server crashed during initialization
- Port conflicts preventing server from binding
- Configuration errors in Rails environment
- Resource constraints during server boot

**Solutions**:
- Check Rails server logs for startup errors
- Verify ports are available and not in use
- Check environment configuration for production mode
- Ensure database and other dependencies are available
- Monitor resource usage during server startup
- Try starting the server manually to debug issues

## rake_change_in_worker_queues

**Description**: Changes detected in Sidekiq worker queue configurations that require metadata updates.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Changes in worker queues found, please update the metadata by running`

**Causes**:
- Worker queue configuration changed without updating metadata
- Queue routing rules modified
- New workers added without proper queue assignment
- Queue priority changes not reflected in metadata
- Sidekiq configuration changes not properly documented

**Solutions**:
- Run the command suggested in the error message to update metadata
- Ensure queue changes follow proper workflow
- Update worker queue assignments consistently
- Review Sidekiq configuration documentation
- Follow proper procedure for adding or modifying worker queues
- Commit updated metadata files with your changes

## rake_db_unknown_schema

**Description**: References to undefined database schemas in rake tasks, usually when configuration files are missing schema definitions.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Gitlab::Database::GitlabSchema::UnknownSchemaError`

**Causes**:
- Missing schema definition in database dictionary
- Incorrect schema reference in database operations
- Configuration files missing required schema mappings
- Database operations using undefined schemas
- Table referenced but not defined in database catalog

**Solutions**:
- Add the missing schema definition to db/docs yaml files
- Run `bin/rails gitlab:db:dictionary:generate` to update definitions
- Check for typos in schema references
- Ensure tables are properly categorized in the database dictionary
- Review database architecture documentation for schema requirements

## rake_enqueue_from_transaction

**Description**: Attempts to enqueue Sidekiq jobs from within database transactions, which can lead to race conditions if the job runs before the transaction is committed.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Sidekiq::Job::EnqueueFromTransactionError`

**Causes**:
- Enqueuing Sidekiq jobs inside a database transaction
- Service objects creating jobs while in transactions
- Missing transaction awareness in job scheduling code
- Callbacks triggering job creation within transactions
- Complex nested operations with implicit transactions

**Solutions**:
- Move job enqueuing outside of transaction blocks
- Use `after_commit` callbacks instead of `after_save`
- Set up a post-transaction callback to create jobs
- Use ApplicationRecord.transaction_open? to check before enqueuing
- Refactor code to separate transaction and job creation logic
- Use transactional_memoized_method for design pattern examples

## rake_invalid_feature_flag

**Description**: Invalid feature flag configurations detected, such as improper default settings or missing definition files.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Feature::InvalidFeatureFlagError: `

**Causes**:
- Feature flag definition missing required attributes
- Invalid default value for feature flag
- Inconsistent feature flag configuration
- Improper feature flag type specification
- Missing or incorrect feature group definitions

**Solutions**:
- Check feature flag definition for required attributes
- Ensure default values are appropriate for flag type
- Follow feature flag definition guidelines
- Verify feature groups are properly defined
- Review feature flag documentation for correct structure
- Test feature flag configuration in development environment

## rake_new_version_of_sprockets

**Description**: Outdated Sprockets asset pipeline patching that is no longer needed with newer versions of Sprockets.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `New version of Sprockets detected. This patch can likely be removed.`

**Causes**:
- Upgraded Sprockets version but kept old patches
- Legacy compatibility code no longer needed
- Asset pipeline configuration outdated
- Custom Sprockets patches that conflict with new version
- Mixture of old and new Sprockets configuration

**Solutions**:
- Remove the outdated Sprockets patches
- Update asset pipeline configuration for newer version
- Check for deprecated Sprockets features being used
- Follow upgrade guide for current Sprockets version
- Test asset compilation after removing patches
- Update custom extensions to use current Sprockets API

## rake_outdated_translated_strings

**Description**: Outdated translation strings that need to be updated to match changes in the source language strings.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Changes in translated strings found, please update file`

**Causes**:
- Source language strings changed but translations not updated
- New strings added without translations
- Translation files out of sync with source code
- Removed strings still present in translation files
- Translation process not completed for recent changes

**Solutions**:
- Run the command suggested in the error to update translation files
- Update translations for changed source strings
- Remove translations for strings no longer in use
- Follow translation workflow for string changes
- Use proper internationalization practices for new strings

## rake_rails_unknown_primary_key

**Description**: Missing primary key definitions in ActiveRecord models, which can cause issues with record identification and association management.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ActiveRecord::UnknownPrimaryKey`

**Causes**:
- Model class doesn't define primary_key and table has no id column
- Custom primary key not specified in model
- Table created without primary key
- Accessing a view or query result without defined primary key
- Joining tables in a way that obscures primary key

**Solutions**:
- Add explicit primary_key definition to model: `self.primary_key = 'column_name'`
- Ensure tables have appropriate primary keys
- For views or custom queries, define primary_key or use methods that don't require it
- Check schema design for tables without proper primary keys
- Consider adding composite primary keys if appropriate

## rake_some_po_files_invalid

**Description**: Invalid translation files (PO files) detected during rake tasks, usually containing syntax errors or formatting issues.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Not all PO-files are valid`

**Causes**:
- Syntax errors in PO files
- Incorrect formatting in translation strings
- Missing or invalid message IDs
- Unescaped special characters in translations
- Inconsistent line endings or encoding issues

**Solutions**:
- Check syntax of invalid PO files
- Fix formatting issues in translation strings
- Ensure proper escaping of special characters
- Validate PO files with tools like msgfmt
- Use consistent encoding (usually UTF-8)
- Follow gettext PO file formatting guidelines

## rake_task_not_found

**Description**: Referenced rake tasks that don't exist, typically due to typos or removed tasks.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Don't know how to build task.+See the list of available tasks with`

**Causes**:
- Attempting to run a rake task that doesn't exist
- Typo in rake task name
- Task was removed or renamed
- Missing gem or plugin that provides the task
- Task defined in a file that isn't loaded

**Solutions**:
- Check for typos in the task name
- Run `rake -T` to see available tasks
- Verify the task still exists in current version
- Ensure all required gems are installed
- Check if task requires a namespace prefix
- Look for deprecated tasks that might have been removed

## rake_unallowed_schemas_accessed

**Description**: Unauthorized access attempts to restricted database schemas during rake tasks, which can happen when code tries to access tables outside its allowed scope.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError:`

**Causes**:
- Query accessing tables in restricted or unauthorized schemas
- Incorrect database connection used for schema-specific operations
- Code not respecting database architecture boundaries
- Migrations or rake tasks trying to span multiple schemas
- Missing proper connection switching logic

**Solutions**:
- Ensure queries only access tables in allowed schemas
- Use appropriate connection objects for different schemas
- Refactor code to respect schema boundaries
- Follow GitLab's database architecture guidelines
- Check documentation: https://docs.gitlab.com/ee/development/database/multiple_databases.html

## redis

**Description**: Redis connection or operation issues, affecting caching, queuing, and other Redis-dependent services.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Redis client could not fetch cluster information`

**Causes**:
- Redis server not running or unreachable
- Authentication failures with Redis
- Redis cluster configuration issues
- Network connectivity problems
- Redis memory or resource exhaustion

**Solutions**:
- Verify Redis server is running and accessible
- Check Redis connection configuration
- Ensure authentication credentials are correct
- For clusters, verify all nodes are healthy
- Check Redis server logs for specific errors
- Monitor Redis memory usage and resource constraints

## rspec_at_80_min

**Description**: RSpec test suite timeouts at the 80-minute mark, a specific limit set for GitLab's test suite to prevent excessively long-running tests. Test suites exceeding this limit are forcibly terminated.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Rspec suite is exceeding the 80 minute limit and is forced to exit with error`

**Causes**:
- Test suite contains too many or too slow tests for the time limit
- Inefficient tests with unnecessary setup or operations
- Tests waiting on slow external resources
- Test ordering causing slow tests to run together
- Resource contention on CI runners

**Solutions**:
- Optimize slow tests to improve execution time
- Split test files into smaller groups
- Use proper mocking and stubbing to avoid slow external calls
- Consider moving very slow tests to a separate job
- Profile test execution to identify bottlenecks
- Use parallelization with knapsack to distribute test load

## rspec_test_already_failed_on_default_branch

**Description**: Tests that are already failing on the default branch, indicated by exit code 112. These failures are not introduced by the current changes.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `ERROR: Job failed: exit code 112`

**Causes**:
- Test already failing on the default branch
- Broken master or main branch tests
- Known flaky tests that need attention
- Legacy test failures that aren't yet fixed
- Infrastructure issues affecting both branches

**Solutions**:
- Ignore these failures as they're not caused by your changes
- Consider fixing the broken test on the default branch separately
- Add issue to track persistent test failures
- Check if test is marked as quarantined
- If fixing in the current MR, note that it addresses existing failures
- For widespread issues, escalate to maintainers

## rspec_undercoverage

**Description**: Insufficient test coverage detected in the codebase, where methods or classes lack adequate test coverage.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `some methods have no test coverage!`

**Causes**:
- New code added without corresponding tests
- Tests exist but don't execute all code paths
- Missing test cases for edge conditions
- Test execution not reaching all methods
- Coverage calculation issues

**Solutions**:
- Add tests for uncovered methods
- Expand existing tests to cover more code paths
- Check coverage reports to identify specific gaps
- Follow TDD practices to ensure coverage
- Update coverage thresholds if necessary
- For intentional exceptions, document why coverage isn't needed

## rspec_usage

**Description**: Improper usage of RSpec testing framework features, including issues with doubles, shared contexts, and other testing patterns.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported.`
- `Could not find shared context`
- `Could not find shared examples`
- `is not available on an example group`
- `WebMock::NetConnectNotAllowedError`

**Causes**:
- Using test doubles outside proper lifecycle
- Missing or incorrectly referenced shared contexts/examples
- Incorrect RSpec API usage
- WebMock preventing allowed network connections
- RSpec configuration or setup issues

**Solutions**:
- Only create test doubles within proper test lifecycle methods
- Verify shared context/example names and paths
- Ensure proper RSpec API usage according to documentation
- For WebMock issues, allow necessary connections or use stub_request
- Review RSpec best practices and correct usage patterns
- Check for typos in shared context or example names

## rspec_valid_rspec_errors_or_flaky_tests

**Description**: Legitimate RSpec test failures that indicate actual code issues or flaky tests, as opposed to infrastructure problems.

These include expectation failures (expected vs. got), assertion failures, and other test-specific errors. The patterns match logs that contain both the 'Failed examples:' section and either expectation outputs or general failure messages.

When you see this failure category, it likely means there's an actual issue with the code or tests that needs to be addressed, rather than a CI infrastructure problem.

**Source File**: `multiline_patterns.yml`

**Patterns**:
- `Failed examples:,expected( :| #| \[ | \`)`
- `Failed examples:,Failure/Error:`

**Causes**:
- Actual test failures due to code not meeting expectations
- Flaky tests that pass locally but fail intermittently in CI
- Race conditions in tests
- Time-dependent tests that are sensitive to execution speed
- Tests affected by state from other tests

**Solutions**:
- Review the failure message to understand the specific expectation that's failing
- Run the specific failing test locally: `bin/rspec <file_path>:<line_number>`
- Check if the test is flaky by running it multiple times: `bin/rspec <file_path>:<line_number> --repeat 10`
- If the test is flaky, consider adding it to quarantine with the :quarantine tag
- For race conditions, ensure proper test isolation and avoid relying on execution order
- For consistent failures, fix the underlying code to match expectations or update the test if expectations have changed

## ruby_bundler_command_failed

**Description**: Failures when Bundler attempts to load and execute Ruby commands, often due to dependency issues, environment problems, or errors in the executed command itself.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `bundler: failed to load command: `

**Causes**:
- Missing gem dependencies
- Execution permission issues
- Errors in the script being executed
- Environment configuration problems
- Path or Ruby version mismatches

**Solutions**:
- Run `bundle install` to ensure all dependencies are installed
- Check execution permissions on the command (`chmod +x` if needed)
- Review script for errors or compatibility issues
- Check Ruby version compatibility
- Ensure environment variables are correctly set
- Look for details in error traces following this message

## ruby_could_not_load_file

**Description**: Ruby cannot load required files or libraries, which may be due to missing gems, incorrect load paths, or dependency issues. These errors prevent code from being properly loaded and executed.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `LoadError:`
- `cannot load such file`

**Causes**:
- Missing gem dependencies
- Incorrect load paths
- Gems installed but not properly required
- Mismatched gem versions between Gemfile.lock and installed gems
- Native extension build failures during gem installation

**Solutions**:
- Run `bundle install` to ensure all dependencies are installed
- Check `require` statements for correct file paths and naming
- Verify that the gem is listed in your Gemfile
- For native extensions, ensure development headers are installed (e.g., `libpq-dev` for pg gem)
- Try `bundle pristine` to reinstall gems from scratch
- Check for path issues in require statements - remember Ruby load paths are relative

## ruby_crash_core_dump

**Description**: Ruby interpreter crashes with a core dump, often showing stack traces with 'Control frame information'. These indicate severe runtime errors like memory corruption or bugs in C extensions that cause the Ruby VM to terminate unexpectedly.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Control frame information`

**Causes**:
- Memory corruption in Ruby VM
- Bugs in native C extensions
- Stack overflow due to infinite recursion
- Segmentation faults in the Ruby interpreter
- YJIT (Ruby's JIT compiler) bugs

**Solutions**:
- Check for recent gem updates that might have introduced C extension issues
- Look for recursive code that might cause stack overflow
- Run without YJIT by setting `RUBY_YJIT_ENABLE=0`
- Try reproducing locally to collect more detailed crash information
- If reproducible, report the issue to the Ruby core team or relevant gem maintainers

## ruby_eof

**Description**: Unexpected end-of-file errors in Ruby, typically occurring when reading from streams or files that unexpectedly terminate. Often seen in network operations or file parsing.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `EOFError`

**Causes**:
- Attempting to read beyond the end of a file or stream
- Network connection closed unexpectedly during read operation
- File truncated or corrupted
- Socket connection closed by remote server
- Misuse of IO methods without proper checks for end-of-file condition

**Solutions**:
- Add proper error handling for read operations
- Use conditional read methods that check for EOF (`read_nonblock` with exception: false)
- Implement retry logic for network operations
- Verify file integrity before reading
- For sockets, check connection status before attempting to read
- Add timeout handling for blocking IO operations

## ruby_frozen

**Description**: Attempts to modify frozen (immutable) objects in Ruby, such as strings, arrays, or hashes that have been marked as read-only. Occurs when code tries to alter objects that have been frozen with the freeze method.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `FrozenError:`

**Causes**:
- Attempting to modify a frozen object
- Ruby constants are implicitly frozen in recent Ruby versions
- Objects frozen by `freeze` method call
- Strings in string literals with frozen_string_literal pragma
- Modifying objects returned from methods that return frozen instances

**Solutions**:
- Create a duplicate using `.dup` before modifying the object
- For strings, use unfrozen string literals with `# frozen_string_literal: false`
- Check if an object is frozen before attempting modification with `.frozen?`
- Redesign code to avoid modifying frozen objects
- For constants, assign a new value rather than trying to modify in place

## ruby_generic_failure

**Description**: Generic Ruby errors that don't match more specific categories, typically shown in RSpec test failures or stack traces. Used as a fallback for Ruby errors not captured by other patterns.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Failure/Error:`
- `:in \``

**Causes**:
- Various Ruby errors not covered by more specific categories
- Application-specific exceptions
- Test failures
- Logic errors in code
- Unexpected behaviors in dependencies

**Solutions**:
- Examine the full error message and stack trace for specific causes
- Review the code at the location indicated in the stack trace
- Run failing tests locally with more verbose output
- Check recent changes that might have introduced the issue
- Review application logs for more context

## ruby_gitlab_settings_missing_setting

**Description**: Missing configuration settings in GitLab's settings framework, occurring when code tries to access configuration options that haven't been defined. Usually requires updating configuration files or adding missing settings.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `GitlabSettings::MissingSetting`

**Causes**:
- Setting referenced in code but not defined in configuration
- Configuration file missing required settings
- Environment-specific setting not defined for current environment
- Typo in setting name
- New feature requiring configuration not yet added to settings

**Solutions**:
- Add the missing setting to appropriate configuration file
- Check for typos in setting name used in code
- Ensure setting is defined for the current environment
- Add default value for the setting if appropriate
- Check recent changes that might have introduced new required settings

## ruby_openssl

**Description**: OpenSSL-related errors in Ruby, typically involving SSL certificate validation failures, connection issues, or encryption/decryption problems. Often seen during HTTPS connections to external services.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `OpenSSL::SSL::SSLError`

**Causes**:
- SSL certificate validation failures
- Outdated CA certificates
- Mismatched protocol versions (TLS 1.0/1.1/1.2/1.3)
- Connection resets during SSL handshake
- Invalid certificate or certificate chain
- Hostname verification failures

**Solutions**:
- Update CA certificates on the system or in the Docker image
- Check that the external service supports modern TLS versions
- Verify the SSL certificate is valid and properly configured
- If testing, consider using `OpenSSL::SSL::VERIFY_NONE` for development environments only
- For connection resets, try increasing timeouts or checking network stability
- Ensure hostname in certificate matches the server being accessed

## ruby_runtime_exception

**Description**: Generic runtime exceptions in Ruby code, representing a wide range of operational errors that occur during program execution rather than at parse time.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `RuntimeError`

**Causes**:
- Explicitly raised exceptions without specific type (`raise "error"`)
- Unexpected conditions during code execution
- Logic errors in the application flow
- Unhandled edge cases
- Resource allocation or permission issues

**Solutions**:
- Check the specific error message to understand the cause
- Add more specific exception types rather than generic RuntimeError
- Improve error handling for edge cases
- Add defensive programming checks for potential error conditions
- Look for places where exceptions are being raised explicitly

## ruby_syntax

**Description**: Ruby syntax errors, including unexpected tokens, missing keywords, or malformed code structures. These prevent code from being parsed and must be fixed before execution.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `syntax error, unexpected`
- `SyntaxError`

**Causes**:
- Missing `end` keywords for blocks, methods, or classes
- Unclosed string literals, arrays, or hashes
- Invalid Ruby syntax or attempting to use features from newer Ruby versions
- Mismatched brackets, parentheses, or quotes
- Using reserved keywords as variable or method names

**Solutions**:
- Carefully review code for syntax issues highlighted in the error message
- Use a code editor with syntax highlighting and linting
- Check for matching pairs of brackets, quotes, and `do`/`end` blocks
- Run `rubocop` locally to catch syntax issues before committing
- Ensure code is compatible with the Ruby version used in CI
- For complex syntax issues, simplify the code structure

## ruby_type

**Description**: Ruby type errors where operations are attempted on incompatible types, such as treating a non-module as a module or attempting operations not supported by a particular object type.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `TypeError:`

**Causes**:
- Performing operations on an object that doesn't support them
- Implicit type conversion failures
- Mixing incompatible types in operations
- Using methods that require specific object types
- Attempting to extend or include non-modules

**Solutions**:
- Check object types before operating on them (using `is_a?` or `respond_to?`)
- Add explicit type conversions where needed
- Ensure methods are called on objects that support them
- Refactor code to handle different object types appropriately
- For extension/inclusion errors, ensure you're using a Module, not a Class

## ruby_undefined_method_or_variable

**Description**: References to undefined local variables or methods in Ruby code, typically caused by typos, missing method definitions, or scope issues. These errors occur when code tries to access variables or call methods that don't exist.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `undefined local variable or method \``
- `undefined method \``

**Causes**:
- Typos in method or variable names
- Method defined in a different scope than where it's called
- Missing require statements for modules that define the method
- Calling methods on nil values (NoMethodError)
- Using a method that was renamed or removed
- Method defined as private or protected but called from outside context

**Solutions**:
- Check for typos in the method or variable name
- Ensure the method is defined in the correct scope and properly required
- Add nil checks before calling methods on potentially nil objects
- Verify method visibility (public/private/protected) matches how it's being called
- Check the method signature for any recent changes
- For class methods, ensure using `.method` (not `#method`) notation in documentation

## ruby_uninitialized_constant

**Description**: References to Ruby constants (classes or modules) that haven't been defined or properly loaded. Often occurs due to missing requires, autoloading issues, or namespace problems.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `uninitialized constant `

**Causes**:
- Missing `require` statement for file defining the constant
- Namespace resolution issues (e.g., using `ClassName` instead of `Module::ClassName`)
- Autoloading failures
- Typos in constant names
- Circular dependencies preventing proper initialization

**Solutions**:
- Add necessary `require` statements at the top of the file
- Check for correct namespace resolution, using full path when needed (`::ClassName`)
- Verify spelling of constant names
- For Rails, ensure autoload paths include the correct directories
- Break circular dependencies by restructuring code
- Make sure the constant is defined before it's used

## ruby_unknown_keyword

**Description**: Method calls with unknown keyword arguments, usually due to API changes, typos in keyword names, or version mismatches between libraries.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `unknown keyword:`

**Causes**:
- Method API changed, removing previously supported keywords
- Typos in keyword argument names
- Using keyword arguments with methods that don't support them
- Library version mismatch with incompatible method signatures
- Missing required keyword arguments

**Solutions**:
- Check method documentation for supported keyword arguments
- Review for typos in keyword names
- Update code to match changed APIs in newer versions
- Check for version mismatches in dependencies
- Ensure using the correct method signature

## ruby_wrong_argument_type

**Description**: Type mismatch errors where methods receive arguments of the wrong type. These occur when a method expects one type of object (like a Module) but receives another (like a Class).

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `wrong argument type.+expected.+`

**Causes**:
- Passing an object of incorrect type to a method
- Type conversion errors (e.g., trying to convert non-numeric string to number)
- Class vs. Module confusion in metaprogramming
- Using a symbol when a string is expected or vice versa
- Passing wrong object type to built-in methods

**Solutions**:
- Check the method signature and ensure arguments match expected types
- Add explicit type conversion where needed (e.g., `to_s`, `to_i`, etc.)
- For complex types, verify the object's class with `object.class` or `object.is_a?`
- Review documentation for correct argument types
- Consider adding type validation at the beginning of methods

## ruby_wrong_number_of_arguments

**Description**: Method calls with an incorrect number of arguments, either too few or too many. Usually caused by API changes or misunderstanding of method signatures.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `wrong number of arguments \(gven`

**Causes**:
- Calling a method with too many or too few arguments
- API changes that modified method signatures
- Confusion between different method overloads
- Missing or extra required arguments
- Using positional arguments when keywords are expected or vice versa

**Solutions**:
- Check method documentation for correct number of arguments
- Update method calls to match the expected signature
- For API changes, update code to conform to new signatures
- Make sure required arguments are provided
- Check if you're mixing positional and keyword arguments incorrectly

## ruby_yjit_panick

**Description**: Panic errors in Ruby's YJIT (Yet Another Just-In-Time) compiler, which accelerates Ruby code execution. YJIT panics typically indicate internal compiler bugs or memory-related issues in the JIT implementation.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `ruby: YJIT has panicked`

**Causes**:
- Bugs in YJIT implementation
- Unsupported Ruby language features used with YJIT
- Memory issues in the JIT compilation process
- Incompatibilities between Ruby version and YJIT version

**Solutions**:
- Disable YJIT by setting `RUBY_YJIT_ENABLE=0` environment variable
- Update to the latest Ruby patch version which may contain YJIT fixes
- Report the issue to Ruby core team with reproducible example if possible
- Check for known YJIT issues in the Ruby issue tracker

## rubocop

**Description**: Ruby code style and quality issues detected by RuboCop, the Ruby linter and static code analyzer used in GitLab's backend development.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `offenses? detected`
- `=== Filtered warnings ===`

**Causes**:
- Ruby code not following style guidelines
- Code quality issues detected by static analysis
- Formatting inconsistencies in Ruby code
- Use of deprecated or discouraged Ruby patterns
- Missing documentation or code structure issues

**Solutions**:
- Run RuboCop locally to identify issues: `bundle exec rubocop`
- Fix style issues with auto-correct when possible: `bundle exec rubocop -a`
- Address specific rule violations mentioned in output
- Follow GitLab's Ruby style guide
- For unavoidable violations, use inline comments to disable specific rules
- Keep .rubocop.yml updated if rules need adjustments

## shell_command_not_found

**Description**: References to commands that don't exist or aren't in the system PATH, typically due to missing dependencies, uninstalled tools, or typos in command names.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `: command not found`

**Causes**:
- Command is not installed on the system
- Command is installed but not in the PATH
- Typo in command name
- Attempting to use an alias that isn't defined
- Missing dependency not installed in CI environment

**Solutions**:
- Install the required command or package
- Check for typos in the command name
- Use full paths for commands in non-standard locations
- Add the command's directory to PATH
- Verify dependencies in CI configuration
- For Docker-based CI, ensure command is installed in the Docker image

## shell_could_not_gzip

**Description**: Failures when attempting to compress files with gzip, particularly when the input stream ends unexpectedly. May indicate truncated files or interrupted streams.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `gzip: stdin: unexpected end of file`

**Causes**:
- Input file or stream is truncated or corrupt
- Pipe to gzip interrupted unexpectedly
- Disk space issues during compression
- Input source ended prematurely
- Network interruption during streaming

**Solutions**:
- Verify input file integrity before compression
- Check for disk space issues
- Ensure input streams are complete before compression
- Add error handling for compression operations
- For pipelines, ensure upstream commands complete successfully

## shell_file_not_found

**Description**: Attempts to access files or directories that don't exist in shell commands, often due to incorrect paths, missing files, or failed file generation steps.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `: No such file or directory`

**Causes**:
- File or directory does not exist at the specified path
- Incorrect path used in command
- File was expected to be generated but wasn't
- File was deleted or moved before access
- Path typos or incorrect variable expansion

**Solutions**:
- Verify file paths are correct and files exist
- Use absolute paths when relative paths might be ambiguous
- Check if previous steps that should generate the file completed successfully
- Ensure working directory is what you expect with `pwd`
- Debug by listing directory contents with `ls -la`

## shell_not_in_function

**Description**: Shell script errors related to function context, typically when using function-specific commands like 'return' outside of a function definition.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `: not in a function`

**Causes**:
- Using `return` statement outside of a function
- Function-specific constructs used in global scope
- Attempting to access function-local variables from outside
- Issues with bash script structure

**Solutions**:
- Only use `return` inside function definitions
- Replace `return` with `exit` in top-level script context
- Ensure function definitions are correct (proper syntax)
- Restructure script to properly encapsulate functionality in functions
- Check for missing function definition or scope issues

## shell_permission

**Description**: Permission denied errors in shell commands, typically due to insufficient file access rights, attempting to write to read-only locations, or execute files without execute permissions.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `: Permission denied`

**Causes**:
- Insufficient file or directory permissions
- Attempting to write to a read-only filesystem
- Executing a script without the executable bit set
- User or CI runner lacks necessary permissions
- Attempting to access protected system resources

**Solutions**:
- Check file permissions with `ls -l` and adjust with `chmod` if needed
- For scripts, ensure they have execute permission (`chmod +x script.sh`)
- Use a different directory with appropriate permissions
- Check if the CI runner has necessary permissions
- Run operations as appropriate user with proper privileges

## shell_readonly_variable

**Description**: Attempts to modify read-only shell variables, which are protected from changes. Often seen with environment variables or constants that shouldn't be altered during execution.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `readonly variable`

**Causes**:
- Attempting to modify a variable declared with `readonly`
- Trying to change internal shell variables that are read-only
- Redefining environment variables that are protected
- Shell or system configuration that makes certain variables immutable

**Solutions**:
- Avoid modifying readonly variables; use different variable names instead
- Check which variables are readonly using `readonly -p`
- Redesign script to work without modifying readonly variables
- For environment setup, set variables before they become readonly
- If necessary, create a subshell where variables can be redefined

## shell_syntax

**Description**: Shell script syntax errors, including malformed commands, missing quotes, incorrect control structures, or other bash syntax issues that prevent script execution.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `: syntax error`

**Causes**:
- Missing or unmatched quotes, parentheses, or brackets
- Invalid syntax in control structures (if, for, while)
- Incorrect command substitution
- Misplaced or missing semicolons
- Using bash features in a more restricted shell

**Solutions**:
- Check for unmatched quotes, brackets, or parentheses
- Validate shell script syntax with a linter like shellcheck
- Use proper quoting for variables and expansions
- Ensure script is using the intended shell (bash, sh, etc.)
- Simplify complex expressions or break them into smaller parts

## shell_unbound_variable

**Description**: References to undefined shell variables in bash scripts, occurring when scripts attempt to use variables that haven't been set or have gone out of scope.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `unbound variable`

**Causes**:
- Using a variable that hasn't been defined
- Typo in variable name
- Environment variable expected but not set
- Variable set in a subshell but used in parent shell
- Missing `export` for variables meant to be available in child processes

**Solutions**:
- Check for typos in variable names
- Ensure variables are defined before use
- Use default values with `${VAR:-default}` syntax
- Add error handling for missing variables
- Set `set -u` to catch unbound variables early
- For CI variables, ensure they're defined in settings

## ssl_connect_reset_by_peer

**Description**: SSL connection reset errors during secure communications, often due to network interruptions, server-side SSL configuration issues, or certificate problems.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `Connection reset by peer - SSL_connect`

**Causes**:
- Network interruption during SSL handshake
- Server closed connection during negotiation
- SSL protocol version mismatch
- Cipher suite incompatibility
- Server-side SSL configuration issues
- Firewall or proxy interfering with SSL traffic

**Solutions**:
- Check network stability and connectivity
- Verify SSL/TLS configuration on both client and server
- Try specifying compatible TLS version explicitly
- Add retry logic for transient connection issues
- Check for server-side SSL configuration changes
- Verify that firewalls or proxies allow SSL connections

## unexpected

**Description**: Generic unexpected errors that don't match other categories, serving as a catch-all for miscellaneous issues. These often require manual investigation to determine the root cause.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `An unexpected error occurred`

**Causes**:
- Various unclassified errors
- Edge cases not handled by more specific error patterns
- Unusual environmental or configuration issues
- Multiple failures occurring simultaneously
- New or rare error conditions without specific patterns

**Solutions**:
- Examine the full error logs for more specific information
- Try to reproduce the issue locally for better debugging
- Check recent changes that might have introduced the issue
- Look for environment-specific factors that might be relevant
- Consider adding a more specific error pattern if this occurs frequently

## unknown_failure_canceled

**Description**: Job cancellations with unclear causes, possibly due to manual cancellation, GitLab Runner interruptions, or system-level issues. These jobs are terminated before normal completion.

**Source File**: `catchall_patterns.yml`

**Patterns**:
- `ERROR: Job failed: canceled`

**Causes**:
- Manual job cancellation
- Runner shutdown or failure
- System resource constraints leading to termination
- Timeout at system or orchestration level
- Dependency job failure causing cancellation
- GitLab CI/CD system issues

**Solutions**:
- Check if the job was manually canceled
- Look for system events that might have caused runner issues
- Check for resource constraints (CPU, memory, disk)
- Examine dependency jobs that might have triggered cancellation
- Retry the job to see if it was a transient issue
- Check GitLab status page for system-wide issues

## vuejs3

**Description**: Compatibility issues with Vue.js 3 migrations, as GitLab transitions from Vue 2 to Vue 3 in its frontend code.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Expected unset environment variable`
- `either now pass under Vue 3, or no longer exist`

**Causes**:
- Vue 3 compatibility breaking changes
- Components using deprecated Vue 2 features
- Migration issues between Vue versions
- Environment configuration issues
- Tests expecting Vue 2 behavior in Vue 3 context

**Solutions**:
- Update components to follow Vue 3 compatibility guidelines
- Remove use of deprecated Vue 2 features
- Check migration guide for required changes: https://v3-migration.vuejs.org/
- Fix environment variable configuration as specified in error
- Update tests to work with Vue 3 behavior
- For complex components, consider incremental migration approach

## webpack_cli

**Description**: Webpack CLI execution errors, typically related to file system operations during the build process.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `webpack-cli.+Error: EEXIST: file already exists`

**Causes**:
- File system conflicts during build
- Concurrent builds writing to same location
- Incomplete cleanup from previous builds
- Permission issues with output directories
- Webpack configuration targeting existing files without overwrite

**Solutions**:
- Clean build output directory before compiling
- Fix webpack configuration to handle existing files
- Ensure proper permissions on output directories
- Add error handling for file system operations
- Avoid concurrent builds to same output location
- Check for disk space or inode exhaustion

## yaml_lint_failed

**Description**: YAML syntax and formatting issues detected by yamllint, which checks for problems in YAML configuration files.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `yamllint `

**Causes**:
- YAML syntax errors
- Indentation issues in YAML files
- Line length violations
- Missing or duplicate keys
- Incorrect spacing or formatting

**Solutions**:
- Fix YAML syntax errors
- Correct indentation (usually 2 spaces)
- Resolve line length and structure issues
- Check for duplicate keys
- Validate YAML files with tools like yamllint locally
- Follow YAML best practices and style guides

## yarn_dependency_violation

**Description**: Peer dependency violations in Yarn packages, where installed packages don't meet the version requirements of their dependents.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `Peer dependency violation`

**Causes**:
- Package versions not satisfying peer dependencies
- Conflicting version requirements between packages
- Outdated dependencies with incompatible peers
- Using packages with explicit version constraints
- Major version upgrades with breaking changes

**Solutions**:
- Update package versions to satisfy peer dependencies
- Resolve version conflicts by updating packages
- Check for available versions that satisfy all peers
- For complex conflicts, consider yarn resolutions
- Update dependent packages to versions with compatible requirements
- Review package release notes for compatibility changes

## yarn_run

**Description**: Failures in Yarn script execution, typically in frontend build, test, or lint commands.

**Source File**: `single_line_patterns.yml`

**Patterns**:
- `yarn run.+failed with the following error`

**Causes**:
- Script configuration errors
- Build process failures
- Missing dependencies or tools
- Environment configuration issues
- Node.js version incompatibilities
- Resource constraints during build

**Solutions**:
- Check the specific error in the yarn script output
- Run the failing script locally to debug
- Verify all dependencies are installed
- Check for Node.js version requirements
- Review script configuration in package.json
- Look for recent changes that might affect the build process

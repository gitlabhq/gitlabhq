# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ApplicationRateLimiter characteristic hash parity', feature_category: :system_access do
  it_behaves_like 'application rate limiter characteristic hash parity' do
    let(:rows) do
      [
        [:users_get_by_id, user, { user: user }],
        [:project_fork_sync, [project, user], { project: project, user: user }],
        [:notification_emails, [project, user], { project: project, user: user }],
        [:notification_emails, [group, user], { group: group, user: user }],
        [:notification_emails, [nil, user].flatten, { user: user }],
        [:fetch_google_ip_list, :global, { scope: :global }],
        [:email_verification, 'person@example.com', { subject: 'person@example.com' }],
        [:email_verification, :global, { subject: :global }],
        [:permanent_email_failure, 'person@example.com', { email: 'person@example.com' }],
        [:glql, 'abc123sha', { query_sha: 'abc123sha' }],
        [:project_import, [user, :project_import], { user: user, action: :project_import }],
        [:pipelines_create, [project, user, 'deadbeef'], { project: project, user: user, sha: 'deadbeef' }],
        [:downstream_pipeline_trigger, [project, user, 'deadbeef'], { project: project, user: user, sha: 'deadbeef' }],
        [:gitlab_shell_operation, ['git-upload-pack', 'group/repo.git', user],
          { action: 'git-upload-pack', repo_path: 'group/repo.git', user: user }],
        [:gitlab_shell_operation, ['git-upload-pack', 'group/repo.git', deploy_key],
          { action: 'git-upload-pack', repo_path: 'group/repo.git', key: deploy_key }],
        [:gitlab_shell_operation, ['git-upload-pack', 'group/repo.git', '1.2.3.4'],
          { action: 'git-upload-pack', repo_path: 'group/repo.git', ip: '1.2.3.4' }],
        [:gitlab_shell_operation, ['git-upload-pack', 'group/repo.git', deploy_token],
          { action: 'git-upload-pack', repo_path: 'group/repo.git', ip: deploy_token.to_s }],
        [:web_hook_calls, [group], { namespace: group }],
        [:search_rate_limit, [user, 'blobs'], { user: user, search_scope: 'blobs' }],
        [:search_rate_limit, [user, nil].compact, { user: user, search_scope: nil }],
        [:search_rate_limit_unauthenticated, ['1.2.3.4'], { ip: '1.2.3.4' }],
        [:play_pipeline_schedule, [user, pipeline_schedule], { user: user, ci_pipeline_schedule: pipeline_schedule }],
        [:raw_blob, [project, 'app/file.rb'], { project: project, path: 'app/file.rb' }],
        [:update_environment_canary_ingress, [environment], { environment: environment }],
        [:import_source_user_notification, [import_source_user], { import_source_user: import_source_user }],
        [:expanded_diff_files, user, { user: user }],
        [:expanded_diff_files, '1.2.3.4', { ip: '1.2.3.4' }]
      ]
    end
  end
end

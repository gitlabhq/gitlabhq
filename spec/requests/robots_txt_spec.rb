# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Robots.txt Requests', :aggregate_failures, feature_category: :shared do
  before do
    Gitlab::Testing::RobotsBlockerMiddleware.block_requests!
  end

  after do
    Gitlab::Testing::RobotsBlockerMiddleware.allow_requests!
  end

  it 'allows the requests' do
    requests = [
      '/users/sign_in',
      '/namespace/subnamespace/design.gitlab.com',
      '/users/foo/snippets',
      '/users/foo/snippets/1'
    ]

    requests.each do |request|
      get request

      expect(response).not_to have_gitlab_http_status(:service_unavailable), "#{request} must be allowed"
    end
  end

  it 'blocks the requests' do
    requests = [
      Gitlab::Experiment::Configuration.mount_at,
      '/autocomplete/users',
      '/autocomplete/projects',
      '/search',
      '/admin',
      '/profile',
      '/dashboard',
      '/users',
      '/users/foo',
      '/users/foo@email.com/captcha_check',
      '/users/foo/captcha_check',
      '/api/v1/users/foo/captcha_check',
      '/help',
      '/s/',
      '/-/profile',
      '/-/user_settings/',
      '/-/ide/project',
      '/foo/bar/new',
      '/foo/bar/edit',
      '/foo/bar/raw',
      '/groups/foo/-/analytics',
      '/groups/foo/-/contribution_analytics',
      '/groups/foo/-/group_members',
      '/foo/bar/project.git',
      '/foo/bar/archive/foo',
      '/foo/bar/repository/archive',
      '/foo/bar/activity',
      '/foo/bar/-/blame/',
      '/foo/bar/-/commits',
      '/foo/bar/-/commit',
      '/foo/bar/-/compare/',
      '/foo/bar/-/network/',
      '/foo/bar/-/graphs/',
      '/foo/bar/merge_requests/1.patch',
      '/foo/bar/merge_requests/1.diff',
      '/foo/bar/merge_requests/1/diffs',
      '/foo/bar/-/alert_management',
      '/foo/bar/-/hooks',
      '/foo/bar/services',
      '/foo/bar/-/terraform',
      '/foo/bar/uploads/foo',
      '/foo/bar/-/project_members',
      '/foo/bar/-/settings/',
      '/namespace/subnamespace/design.gitlab.com/-/settings/',
      '/foo/bar/-/import',
      '/foo/bar/-/environments',
      '/foo/bar/-/jobs',
      '/foo/bar/-/requirements_management/requirements',
      '/foo/bar/-/pipelines',
      '/foo/bar/-/pipeline_schedules',
      '/foo/bar/-/dependencies',
      '/foo/bar/-/licenses',
      '/foo/bar/-/metrics',
      '/foo/bar/-/incidents',
      '/foo/bar/-/value_stream_analytics',
      '/foo/bar/-/analytics',
      '/foo/bar/insights/',
      '/groups/foo/bar/-/issues_analytics',
      '/groups/foo/bar/-/saml/',
      '/groups/foo/bar/-/saml_group_links',
      '/foo/bar/-/issues/123/realtime_changes',
      '/groups/group/-/epics/123/realtime_changes'
    ]

    requests.each do |request|
      get request

      expect(response).to have_gitlab_http_status(:service_unavailable), "#{request} must be disallowed"
    end
  end
end

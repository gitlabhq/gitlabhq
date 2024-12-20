# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of user activity', feature_category: :user_profile do
  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }

  paths_to_visit = [
    '/group',
    '/group/project',
    '/groups/group/-/issues',
    '/groups/group/-/boards',
    '/dashboard/projects',
    '/dashboard/snippets',
    '/dashboard/groups',
    '/dashboard/todos',
    '/group/project/-/issues',
    '/group/project/-/issues/10',
    '/group/project/-/merge_requests',
    '/group/project/-/merge_requests/15'
  ]

  it_behaves_like 'updating of user activity', paths_to_visit
end

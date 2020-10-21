# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of user activity' do
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

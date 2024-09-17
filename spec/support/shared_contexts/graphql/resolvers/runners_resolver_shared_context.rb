# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'runners resolver setup' do
  let_it_be(:user) { create_default(:user, :admin) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:subgroup) { create(:group, :public, parent: group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:inactive_project_runner) do
    create(:ci_runner, :project, :paused, :online, projects: [project],
      description: 'paused project runner', token: 'abcdef', tag_list: %w[project_runner])
  end

  let_it_be(:offline_project_runner) do
    create(:ci_runner, :project, :offline, projects: [project],
      description: 'offline project runner', token: 'defghi', tag_list: %w[project_runner active_runner])
  end

  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], token: 'mnopqr', description: 'group runner', contacted_at: 2.seconds.ago) }
  let_it_be(:subgroup_runner) { create(:ci_runner, :group, groups: [subgroup], token: '123456', description: 'subgroup runner', contacted_at: 1.second.ago) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, description: 'shared runner', token: 'stuvxz', contacted_at: 2.minutes.ago, tag_list: %w[instance_runner active_runner]) }
end

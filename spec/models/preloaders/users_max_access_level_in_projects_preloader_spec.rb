# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Preloaders::UsersMaxAccessLevelInProjectsPreloader do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }

  let(:projects) { [project_1, project_2, project_3] }
  let(:users) { [user1, user2] }

  before do
    project_1.add_developer(user1)
    project_1.add_developer(user2)

    project_2.add_developer(user1)
    project_2.add_developer(user2)

    project_3.add_developer(user1)
    project_3.add_developer(user2)
  end

  context 'preload maximum access level to avoid querying project_authorizations', :request_store do
    it 'avoids N+1 queries', :request_store do
      Preloaders::UsersMaxAccessLevelInProjectsPreloader.new(projects: projects, users: users).execute

      expect(count_queries).to eq(0)
    end

    it 'runs N queries without preloading' do
      query_count_without_preload = count_queries

      Preloaders::UsersMaxAccessLevelInProjectsPreloader.new(projects: projects, users: users).execute
      count_queries_with_preload = count_queries

      expect(count_queries_with_preload).to be < query_count_without_preload
    end
  end

  def count_queries
    ActiveRecord::QueryRecorder.new do
      projects.each do |project|
        user1.can?(:read_project, project)
        user2.can?(:read_project, project)
      end
    end.count
  end
end

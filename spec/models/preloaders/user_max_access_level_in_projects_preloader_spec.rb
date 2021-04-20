# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMaxAccessLevelInProjectsPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }

  let(:projects) { [project_1, project_2, project_3] }

  before do
    project_1.add_developer(user)
    project_2.add_developer(user)
  end

  context 'preload maximum access level to avoid querying project_authorizations', :request_store do
    it 'avoids N+1 queries', :request_store do
      Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, user).execute

      query_count = ActiveRecord::QueryRecorder.new do
        projects.each { |project| user.can?(:read_project, project) }
      end.count

      expect(query_count).to eq(0)
    end

    it 'runs N queries without preloading' do
      query_count = ActiveRecord::QueryRecorder.new do
        projects.each { |project| user.can?(:read_project, project) }
      end.count

      expect(query_count).to eq(projects.size)
    end
  end
end

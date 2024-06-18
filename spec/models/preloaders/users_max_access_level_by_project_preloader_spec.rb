# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UsersMaxAccessLevelByProjectPreloader, feature_category: :groups_and_projects do
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:user_with_no_access) { create(:user) } # ensures we correctly cache NO_ACCESS

  let_it_be(:project_1) { create(:project, developers: [user_1, user_2]) }
  let_it_be(:project_2) { create(:project, developers: [user_1, user_2]) }
  let_it_be(:project_3) { create(:project, developers: [user_1, user_2]) }

  describe '#execute', :request_store do
    let(:project_users) do
      {
        project_1 => [user_1, user_with_no_access],
        project_2 => user_2
      }
    end

    it 'avoids N+1 queries' do
      control_input = project_users
      control = ActiveRecord::QueryRecorder.new do
        described_class.new(project_users: control_input).execute
      end

      sample_input = control_input.merge(project_3 => user_2)
      sample = ActiveRecord::QueryRecorder.new do
        described_class.new(project_users: sample_input).execute
      end

      expect(sample).not_to exceed_query_limit(control)
    end

    it 'preloads the max access level used by project policies' do
      described_class.new(project_users: project_users).execute

      policy_queries = ActiveRecord::QueryRecorder.new do
        project_users.each do |project, users|
          Array.wrap(users).each do |user|
            user.can?(:read_project, project)
          end
        end
      end

      expect(policy_queries).not_to exceed_query_limit(1)
    end
  end
end

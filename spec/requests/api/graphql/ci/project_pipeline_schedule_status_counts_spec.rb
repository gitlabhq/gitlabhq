# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.pipelineScheduleStatusCounts',
  feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:stranger) { create(:user) }

  let_it_be(:active_schedule) do
    create(:ci_pipeline_schedule, project: project, active: true)
  end

  let_it_be(:inactive_schedule) do
    create(:ci_pipeline_schedule, project: project, active: false)
  end

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelineScheduleStatusCounts {
            active
            inactive
            total
          }
        }
      }
    )
  end

  let(:counts_data) do
    graphql_data_at(:project, :pipeline_schedule_status_counts)
  end

  describe 'permissions' do
    context 'when user has access to pipeline schedules' do
      before do
        post_graphql(query, current_user: developer)
      end

      it 'returns the pipeline schedule counts' do
        expect(counts_data).to eq(
          'active' => 1,
          'inactive' => 1,
          'total' => 2
        )
      end
    end

    context 'when public pipelines are disabled' do
      before do
        project.update!(public_builds: false)
      end

      context 'when user does not have access' do
        before do
          post_graphql(query, current_user: stranger)
        end

        it 'does not return pipeline schedule counts' do
          expect(counts_data).to be_nil
        end
      end

      context 'when user has access' do
        before do
          post_graphql(query, current_user: developer)
        end

        it 'returns the pipeline schedule counts' do
          expect(counts_data).to eq(
            'active' => 1,
            'inactive' => 1,
            'total' => 2
          )
        end
      end
    end

    context 'when user is not authenticated' do
      context 'with public pipelines enabled' do
        before do
          project.update!(public_builds: true)
          post_graphql(query, current_user: nil)
        end

        it 'returns the pipeline schedule counts' do
          expect(counts_data).to eq(
            'active' => 1,
            'inactive' => 1,
            'total' => 2
          )
        end
      end

      context 'with public pipelines disabled' do
        before do
          project.update!(public_builds: false)
          post_graphql(query, current_user: nil)
        end

        it 'does not return pipeline schedule counts' do
          expect(counts_data).to be_nil
        end
      end
    end
  end
end

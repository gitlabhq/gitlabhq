# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SafeDisablePipelineVariablesService, feature_category: :pipeline_composition do
  let(:log_output) { StringIO.new }
  let(:service) { described_class.new(current_user: current_user, group: parent_group) }

  describe '#execute' do
    subject(:update_role) { service.execute }

    context 'when group_id correctly supplied' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:sub_group1) { create(:group, parent: parent_group) }
      let_it_be(:project_in_group1) { create(:project, group: parent_group) }
      let_it_be(:project_in_sub_group1) { create(:project, group: sub_group1) }
      let_it_be(:expected_updated_projects) { [project_in_group1, project_in_sub_group1] }

      let_it_be(:project_with_variables_in_group1) { create(:project, group: parent_group) }
      let_it_be(:project_with_job_variables_in_group1) { create(:project, group: parent_group) }
      let_it_be(:expected_not_updated_projects) do
        [project_with_variables_in_group1, project_with_job_variables_in_group1]
      end

      let_it_be(:all_projects) { expected_updated_projects + expected_not_updated_projects }

      let_it_be(:current_user) { create(:user) }
      let_it_be_with_reload(:pipeline1) { create(:ci_pipeline, project: project_with_variables_in_group1) }
      let_it_be_with_reload(:pipeline3) { create(:ci_pipeline, project: project_with_job_variables_in_group1) }
      let(:build) { create(:ci_build, pipeline: pipeline3) }

      before do
        create(:ci_pipeline_variable, pipeline: pipeline1, key: :TRIGGER_KEY_1, value: 'TRIGGER_VALUE_1')

        create(:ci_job_variable, job: build)
      end

      before_all do
        ProjectCiCdSetting.update_all(pipeline_variables_minimum_override_role: :developer)
      end

      context 'and current user has permissions to update a group' do
        before_all do
          parent_group.add_owner(current_user)
        end

        it 'updates ci cd settings with minimum override role to no one allowed' do
          response = update_role

          expected_updated_settings = ProjectCiCdSetting.where(project: expected_updated_projects)
          expected_not_updated_settings = ProjectCiCdSetting.where(project: expected_not_updated_projects)

          expect(expected_updated_settings.pluck(:pipeline_variables_minimum_override_role))
            .to eq(%w[no_one_allowed no_one_allowed])

          expect(expected_not_updated_settings.pluck(:pipeline_variables_minimum_override_role))
            .to eq(%w[developer developer])

          expect(response.status).to eq(:success)
          expect(response.payload[:updated_count]).to eq(2)
          expect(response.payload[:skipped_count]).to eq(2)
        end

        it 'is idempotent' do
          response = service.execute
          expect(response.status).to eq(:success)

          second_response = service.execute
          expect(second_response.status).to eq(:success)
          expect(second_response.payload[:updated_count]).to eq(0)
          expect(second_response.payload[:skipped_count]).to eq(2)
        end
      end

      context 'and current user has no permissions to update a group' do
        it 'does not updates ci cd settings with minimum override role to no one allowed' do
          response = update_role

          expect(response.status).to eq(:error)
          expect(response.message).to eq('You are not authorized to perform this action')
          expected_updated_settings = ProjectCiCdSetting.where(project: expected_updated_projects)

          expect(expected_updated_settings.pluck(:pipeline_variables_minimum_override_role))
            .to eq(%w[developer developer])
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::VariablesCreateService, feature_category: :ci_variables do
  let_it_be(:reporter) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:developer) { create(:user) }
  let_it_be_with_reload(:project) do
    create(:project, :public, :repository, maintainers: user, developers: developer, reporters: reporter)
  end

  let_it_be_with_reload(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

  subject(:service) { described_class.new(pipeline_schedule, user, params) }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
  end

  describe 'execute' do
    context 'when user does not have permission' do
      subject(:service) { described_class.new(pipeline_schedule, reporter, {}) }

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)

        error_message = _('The current user is not authorized to create the pipeline schedule variables')
        expect(result.message).to match_array([error_message])
        expect(result.payload.errors).to match_array([error_message])
      end
    end

    context 'when user limited with permission on a project' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }

      subject(:service) { described_class.new(pipeline_schedule, developer, {}) }

      before do
        project.update!(restrict_user_defined_variables: true)
      end

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)

        error_message = _('The current user is not authorized to set pipeline schedule variables')
        expect(result.message).to match_array([error_message])
        expect(result.payload.errors).to match_array([error_message])
      end
    end

    context 'when user has permissions' do
      let(:params) do
        {
          key: 'variable1',
          value: 'value1',
          variable_type: 'file'
        }
      end

      subject(:service) { described_class.new(pipeline_schedule, user, params) }

      it 'saves variable with passed params' do
        result = service.execute

        expect(result.payload).to have_attributes(
          key: 'variable1',
          value: 'value1',
          variable_type: 'file'
        )
      end

      it 'returns ServiceResponse.success' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end
    end

    context 'when schedule save fails' do
      subject(:service) { described_class.new(pipeline_schedule, user, {}) }

      before do
        errors = ActiveModel::Errors.new(project)
        errors.add(:base, 'An error occurred')

        allow_next_instance_of(Ci::PipelineScheduleVariable) do |instance|
          allow(instance).to receive(:save).and_return(false)
          allow(instance).to receive(:errors).and_return(errors)
        end
      end

      it 'returns ServiceResponse.error' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to match_array(['An error occurred'])
      end
    end
  end
end

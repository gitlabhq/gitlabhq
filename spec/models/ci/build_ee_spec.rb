require 'spec_helper'

describe Ci::Build, :models do
  let(:project) { create(:empty_project) }
  let(:job) { create(:ci_build, pipeline: pipeline) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
                         ref: 'master',
                         status: 'success')
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_varialbe) do
        { key: 'ENV_KEY', value: 'environment', public: false }
      end

      before do
        job.update(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable =
          build(:ci_variable,
                environment_varialbe.slice(:key, :value)
                  .merge(project: project, environment_scope: 'stag*'))

        # Skip this validation so that we could test for existing data
        allow(variable).to receive(:verify_updating_environment_scope)
          .and_return(true)

        variable.save!
      end

      context 'when variable environment scope is available' do
        before do
          stub_feature(:variable_environment_scope, true)
        end

        it { is_expected.to include(environment_varialbe) }
      end

      context 'when variable environment scope is not available' do
        before do
          stub_feature(:variable_environment_scope, false)
        end

        it { is_expected.not_to include(environment_varialbe) }
      end
    end
  end
end

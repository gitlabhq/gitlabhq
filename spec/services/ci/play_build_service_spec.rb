# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBuildService, '#execute', feature_category: :continuous_integration do
  let(:user) { create(:user, developer_of: project) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, :manual, user: user, pipeline: pipeline) }
  let(:job_variables) { nil }
  let(:job_inputs) { {} }

  let(:service_result) do
    described_class.new(current_user: user, build: build, variables: job_variables, inputs: job_inputs).execute
  end

  subject(:execute_service) { service_result.payload[:job] }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :developer)
  end

  context 'when project does not have repository yet' do
    let(:project) { create(:project) }

    it 'allows user to play build if protected branch rules are met' do
      create(:protected_branch, :developers_can_merge, name: build.ref, project: project)

      execute_service

      expect(build.reload).to be_pending
    end

    it 'does not allow user with developer role to play build' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when project has repository' do
    let(:project) { create(:project, :repository) }

    it 'allows user with developer role to play a build' do
      execute_service

      expect(build.reload).to be_pending
    end

    it 'prevents a blocked developer from playing a build' do
      user.block!

      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when build is a playable manual action' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'enqueues the build' do
      expect(execute_service).to eq build
      expect(build.reload).to be_pending
    end

    it 'reassignes build user correctly' do
      execute_service

      expect(build.reload.user).to eq user
    end

    context 'when a subsequent job is skipped' do
      let!(:job) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: build.stage_idx + 1) }

      it 'marks the subsequent job as processable' do
        expect { execute_service }.to change { job.reload.status }.from('skipped').to('created')
      end
    end

    context 'when variables are supplied' do
      let(:job_variables) do
        [{ key: 'first', secret_value: 'first' },
          { key: 'second', secret_value: 'second' }]
      end

      it 'assigns the variables to the build' do
        execute_service

        expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
      end

      context 'and variables are invalid' do
        let(:job_variables) { [{}] }

        it 'resets the attributes of the build' do
          build.update!(job_variables_attributes: [{ key: 'old', value: 'old variable' }])

          execute_service

          expect(build.job_variables.map(&:key)).to contain_exactly('old')
        end
      end

      context 'when user defined variables are restricted' do
        before do
          project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
        end

        context 'when user is maintainer' do
          before do
            project.add_maintainer(user)
          end

          it 'assigns the variables to the build' do
            execute_service

            expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
          end
        end

        context 'when user is developer' do
          it 'raises an error' do
            expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end
      end
    end

    context 'when inputs are supplied', :aggregate_failures do
      let(:build) do
        create(:ci_build, :manual, pipeline: pipeline, options: {
          inputs: {
            environment: { type: 'string' },
            version: { type: 'string', default: '1.0' }
          }
        })
      end

      let(:job_inputs) { { environment: 'production' } }

      it 'assigns the inputs to the build' do
        execute_service

        expect(build.reload.inputs.map(&:name)).to contain_exactly('environment')
        expect(build.reload.inputs.find_by(name: 'environment').value).to eq('production')
      end

      it 'filters out inputs with default values' do
        job_inputs[:version] = '1.0'

        execute_service

        expect(build.reload.inputs.map(&:name)).to contain_exactly('environment')
      end

      context 'when inputs are invalid' do
        let(:job_inputs) { { unknown_input: 'value' } }

        it 'returns an error response' do
          expect(service_result).to be_a(ServiceResponse)
          expect(service_result.error?).to be true
          expect(service_result.message).to include('Unknown input')
        end

        it 'does not enqueue the build' do
          service_result

          expect(build.reload).to be_manual
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ci_job_inputs: false)
        end

        it 'does not assign inputs to the build' do
          execute_service

          expect(build.reload.inputs).to be_empty
        end
      end
    end
  end

  context 'when build is not a playable manual action' do
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'duplicates the build' do
      duplicate = execute_service

      expect(duplicate).not_to eq build
      expect(duplicate).to be_pending
    end

    it 'assigns users correctly' do
      duplicate = execute_service

      expect(build.user).not_to eq user
      expect(duplicate.user).to eq user
    end

    context 'and is not retryable' do
      let(:build) { create(:ci_build, :deployment_rejected, pipeline: pipeline) }

      it 'does not duplicate the build' do
        expect { execute_service }.not_to change { Ci::Build.count }
      end

      it 'does not enqueue the build' do
        expect { execute_service }.not_to change { build.status }
      end
    end
  end

  context 'when build is not action' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }

    it 'raises an error' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user does not have ability to trigger action' do
    let(:user) { create(:user) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'raises an error' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end

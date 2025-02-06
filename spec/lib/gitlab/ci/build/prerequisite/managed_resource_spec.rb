# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Prerequisite::ManagedResource, feature_category: :continuous_integration do
  describe '#unmet?' do
    let_it_be(:agent_management_project) { create(:project, :private, :repository) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

    let_it_be(:deployment_project) { create(:project, :private, :repository) }
    let_it_be_with_reload(:environment) do
      create(:environment, project: deployment_project, cluster_agent: cluster_agent)
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:deployment) { create(:deployment, environment: environment, user: user) }
    let_it_be_with_reload(:build) { create(:ci_build, environment: environment, user: user, deployment: deployment) }
    let(:status) { :processing }
    let!(:managed_resource) do
      create(:managed_resource,
        build: build,
        project: deployment_project,
        environment: environment,
        cluster_agent: cluster_agent,
        status: status)
    end

    let(:instance) { described_class.new(build) }

    subject(:execute_unmet) { instance.unmet? }

    context 'when resource_management is not enabled' do
      it 'returns false' do
        expect(execute_unmet).to be_falsey
      end
    end

    context 'when resource_management is enabled' do
      before do
        allow(instance).to receive(:resource_management_enabled?).and_return(true)
      end

      context 'when the build is valid for managed resources' do
        context 'when the managed resource record does not exist' do
          let!(:managed_resource) { nil }

          it { is_expected.to be_truthy }
        end

        context 'when managed resources completed successfully' do
          let!(:status) { :completed }

          it 'returns false`' do
            expect(execute_unmet).to be_falsey
          end
        end

        context 'when managed resources failed' do
          let!(:status) { :failed }

          it 'returns true' do
            managed_resource.reload
            expect(execute_unmet).to be_truthy
          end
        end
      end

      context 'when the build does not have a deployment' do
        let_it_be(:build) { create(:ci_build, deployment: nil) }

        it { is_expected.to be_falsey }
      end

      context 'when the build does not have an environment' do
        let_it_be(:build) { create(:ci_build, environment: nil) }

        it { is_expected.to be_falsey }
      end

      context 'when the build does not have a cluster agent' do
        before do
          environment.update!(cluster_agent: nil)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#complete!' do
    let_it_be(:agent_management_project) { create(:project, :private, :repository) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

    let_it_be(:deployment_project) { create(:project, :private, :repository) }
    let_it_be(:environment) { create(:environment, project: deployment_project, cluster_agent: cluster_agent) }
    let_it_be(:user) { create(:user) }
    let_it_be(:deployment) { create(:deployment, environment: environment, user: user) }
    let!(:build) { create(:ci_build, environment: environment, user: user, deployment: deployment) }

    let(:instance) { described_class.new(build) }

    subject(:execute_complete) { instance.complete! }

    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
    end

    context 'when resource_management is not enabled' do
      it 'does nothing' do
        expect(instance).not_to receive(:ensure_environment)
        expect(execute_complete).to be_falsey
      end
    end

    context 'when resource_management is enabled' do
      before do
        allow(instance).to receive(:resource_management_enabled?).and_return(true)
      end

      context 'when #unmet? returns false' do
        before do
          allow(instance).to receive(:unmet?).and_return(false)
        end

        it 'does not ensure the environment and update the status' do
          expect(instance).not_to receive(:ensure_environment)
          expect(instance).not_to receive(:update_status)

          execute_complete
        end
      end

      context 'when #unmet? returns true' do
        before do
          allow(instance).to receive(:unmet?).and_return(true)
        end

        context 'when the build is valid for managed resources' do
          context 'when it successfully ensures the environment' do
            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive_messages(get_environment_template: double,
                  render_environment_template: double)
                success_response = Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentResponse.new(errors: [])
                allow(kas_client).to receive(:ensure_environment).and_return(success_response)
              end
            end

            it 'creates the managed resource record with the completed status' do
              expect { execute_complete }.to change { Clusters::Agents::ManagedResource.count }.by(1)
              managed_resource = Clusters::Agents::ManagedResource.find_by_build_id(build.id)
              expect(managed_resource.status).to eq("completed")
            end
          end

          context 'when get_environment_template raises GRPC::NotFound error' do
            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive(:get_environment_template).and_raise(GRPC::NotFound)
                allow(kas_client).to receive_messages(get_default_environment_template: double,
                  render_environment_template: double)
                success_response = Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentResponse.new(errors: [])
                allow(kas_client).to receive(:ensure_environment).and_return(success_response)
              end
            end

            it 'creates the managed resource record and ensures the environment' do
              expect { execute_complete }.to change { Clusters::Agents::ManagedResource.count }.by(1)
              managed_resource = Clusters::Agents::ManagedResource.find_by_build_id(build.id)
              expect(managed_resource.status).to eq("completed")
            end
          end

          context 'when ensure_environment raises GRPC::InvalidArgument error' do
            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive_messages(get_environment_template: double,
                  render_environment_template: double)
                allow(kas_client).to receive(:ensure_environment).and_raise(GRPC::InvalidArgument)
              end
            end

            it 'creates the managed resource record and leaves it with the processing status' do
              expect { execute_complete }.to raise_error(GRPC::InvalidArgument)
              managed_resource = Clusters::Agents::ManagedResource.find_by_build_id(build.id)
              expect(managed_resource.status).to eq('processing')
            end
          end

          context 'when ensure_environment returns the successful response but with an error information' do
            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive_messages(get_environment_template: double,
                  render_environment_template: double)
                object = {
                  group: 'group',
                  version: 'version',
                  kind: 'kind',
                  name: 'name',
                  namespace: 'namespace'
                }
                error_response = Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentResponse.new(
                  errors: [Gitlab::Agent::ManagedResources::Rpc::ObjectError.new(
                    error: 'error message',
                    object: object
                  )]
                )
                allow(kas_client).to receive(:ensure_environment).and_return(error_response)
              end
            end

            it 'tracks the error and creates the managed resource record with the failed status' do
              error_message = 'Failed to ensure the environment. {"object":{"group":"group","apiVersion":"version",' \
                '"kind":"kind","namespace":"namespace","name":"name"},"error":"error message"}'
              expect { execute_complete }.to raise_error(
                Gitlab::Ci::Build::Prerequisite::ManagedResource::ManagedResourceError, error_message)
              managed_resource = Clusters::Agents::ManagedResource.find_by_build_id(build.id)
              expect(managed_resource.status).to eq('failed')
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Prerequisite::ManagedResource, feature_category: :continuous_delivery do
  describe '#unmet?' do
    let_it_be(:organization) { create(:group) }
    let_it_be(:agent_management_project) { create(:project, :private, :repository, group: organization) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

    let_it_be(:deployment_project) { create(:project, :private, :repository, group: organization) }
    let_it_be(:environment) do
      create(:environment, project: deployment_project, cluster_agent: cluster_agent)
    end

    let_it_be(:user) { create(:user, developer_of: deployment_project) }
    let_it_be(:deployment) { create(:deployment, environment: environment, user: user) }
    let_it_be(:build) do
      create(:ci_build, project: deployment_project, environment: environment, user: user, deployment: deployment)
    end

    let(:status) { :processing }
    let(:managed_resource) do
      create(:managed_resource,
        build: build,
        project: deployment_project,
        environment: environment,
        cluster_agent: cluster_agent,
        status: status)
    end

    let(:instance) { described_class.new(build) }

    subject(:execute_unmet) { instance.unmet? }

    context 'when not valid for managed resources' do
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

    context 'when valid for managed resources' do
      context 'when agent\'s resource management is disabled' do
        before do
          allow_next_instance_of(Clusters::Agent) do |instance|
            allow(instance).to receive(:resource_management_enabled?).and_return(false)
          end
        end

        it 'returns false' do
          expect(execute_unmet).to be_falsey
        end
      end

      context 'when agent\'s resource management is enabled' do
        before do
          environment.reload
          allow(environment.cluster_agent).to receive(:resource_management_enabled?).and_return(true)
        end

        context 'when authorization exists' do
          context 'when the resource_management is not enabled' do
            let_it_be(:agent_ci_access_group_authorization) do
              create(:agent_ci_access_group_authorization, agent: cluster_agent, group: organization)
            end

            context 'when the managed resource record has failed status' do
              let!(:status) { :failed }

              it 'returns false' do
                expect(execute_unmet).to be_falsey
              end
            end
          end

          context 'when authorization exists with resource_management enabled' do
            let_it_be(:agent_ci_access_group_authorization) do
              create(:agent_ci_access_group_authorization, agent: cluster_agent, group: organization,
                config: { resource_management: { enabled: true } })
            end

            context 'when the managed resource record does not exist' do
              let(:managed_resource) { nil }

              it { is_expected.to be_truthy }
            end

            context 'when the managed resource record has completed status' do
              let(:status) { :completed }

              it 'returns false`' do
                managed_resource.reload
                expect(execute_unmet).to be_falsey
              end
            end

            context 'when the managed resource record has failed status' do
              let(:status) { :failed }

              it 'returns true' do
                expect(execute_unmet).to be_truthy
              end
            end
          end
        end
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
    let!(:build) do
      create(:ci_build, environment: environment, user: user, deployment: deployment, project: deployment_project)
    end

    let(:default_template) do
      Gitlab::Agent::ManagedResources::EnvironmentTemplate.new(
        name: 'default',
        data: { objects: [], delete_resources: 'on_stop' }.stringify_keys.to_yaml
      )
    end

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
            let(:namespace_attributes) do
              {
                kind: 'Namespace',
                name: 'production',
                group: '',
                version: 'v1',
                namespace: ''
              }.stringify_keys
            end

            let(:role_binding_attributes) do
              {
                kind: 'RoleBinding',
                name: 'bind-production',
                group: 'rbac.authorization.k8s.io',
                version: 'v1',
                namespace: 'production'
              }.stringify_keys
            end

            let(:success_response) do
              Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentResponse.new(
                errors: [],
                objects: [
                  Gitlab::Agent::ManagedResources::Rpc::Object.new(**namespace_attributes),
                  Gitlab::Agent::ManagedResources::Rpc::Object.new(**role_binding_attributes)
                ]
              )
            end

            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive_messages(get_environment_template: double,
                  render_environment_template: double)

                allow(kas_client).to receive(:get_environment_template)
                  .with(agent: cluster_agent, template_name: 'default')
                  .and_return(default_template)

                rendered_template = double
                allow(kas_client).to receive(:render_environment_template)
                  .with(template: default_template, environment: environment, build: build)
                  .and_return(rendered_template)

                allow(kas_client).to receive(:ensure_environment)
                  .with(template: rendered_template, environment: environment, build: build)
                  .and_return(success_response)
              end
            end

            it 'creates the managed resource record with the completed status' do
              expect { execute_complete }.to change { Clusters::Agents::ManagedResource.count }.by(1)
              managed_resource = Clusters::Agents::ManagedResource.find_by_build_id(build.id)
              expect(managed_resource.status).to eq("completed")
              expect(managed_resource.template_name).to eq('default')
              expect(managed_resource.deletion_strategy).to eq('on_stop')
              expect(managed_resource.tracked_objects).to contain_exactly(namespace_attributes, role_binding_attributes)
            end

            it 'emits an event' do
              expect(Gitlab::InternalEvents).to receive(:track_event)
                .with('ensure_environment_for_managed_resource', user: build.user, project: deployment_project,
                  additional_properties: { label: deployment_project.namespace.actual_plan_name,
                                           property: environment.tier, value: environment.id })

              execute_complete
            end
          end

          context 'when get_environment_template raises GRPC::NotFound error' do
            before do
              allow_next_instance_of(Gitlab::Kas::Client) do |kas_client|
                allow(kas_client).to receive(:get_environment_template).and_raise(GRPC::NotFound)
                allow(kas_client).to receive_messages(get_default_environment_template: default_template,
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

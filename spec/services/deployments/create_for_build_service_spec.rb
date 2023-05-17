# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::CreateForBuildService, feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new }

  describe '#execute' do
    subject { service.execute(build) }

    context 'with a deployment job' do
      let!(:build) { create(:ci_build, :start_review_app, project: project) }
      let!(:environment) { create(:environment, project: project, name: build.expanded_environment_name) }

      it 'creates a deployment record' do
        expect { subject }.to change { Deployment.count }.by(1)

        build.reset
        expect(build.deployment.project).to eq(build.project)
        expect(build.deployment.ref).to eq(build.ref)
        expect(build.deployment.sha).to eq(build.sha)
        expect(build.deployment.deployable).to eq(build)
        expect(build.deployment.deployable_type).to eq('CommitStatus')
        expect(build.deployment.environment).to eq(build.persisted_environment)
        expect(build.deployment.valid?).to be_truthy
      end

      context 'when creation failure occures' do
        before do
          allow_next_instance_of(Deployment) do |deployment|
            allow(deployment).to receive(:save!) { raise ActiveRecord::RecordInvalid }
          end
        end

        it 'trackes the exception' do
          expect { subject }.to raise_error(described_class::DeploymentCreationError)

          expect(Deployment.count).to eq(0)
        end
      end

      context 'when the corresponding environment does not exist' do
        let!(:environment) {}

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(build.deployment).to be_nil
        end
      end
    end

    context 'with a teardown job' do
      let!(:build) { create(:ci_build, :stop_review_app, project: project) }
      let!(:environment) { create(:environment, name: build.expanded_environment_name) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(build.deployment).to be_nil
      end
    end

    context 'with a normal job' do
      let!(:build) { create(:ci_build, project: project) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(build.deployment).to be_nil
      end
    end

    context 'with a bridge' do
      let!(:build) { create(:ci_bridge, project: project) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }
      end
    end

    context 'when build has environment attribute' do
      let!(:build) do
        create(:ci_build, environment: 'production', project: project,
                          options: { environment: { name: 'production', **kubernetes_options } })
      end

      let!(:environment) { create(:environment, project: project, name: build.expanded_environment_name) }

      let(:kubernetes_options) { {} }

      it 'returns a deployment object with environment' do
        expect(subject).to be_a(Deployment)
        expect(subject.iid).to be_present
        expect(subject.environment.name).to eq('production')
        expect(subject.cluster).to be_nil
        expect(subject.deployment_cluster).to be_nil
      end

      context 'when environment has deployment platform' do
        let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project], managed: managed_cluster) }
        let(:managed_cluster) { true }

        it 'sets the cluster and deployment_cluster' do
          expect(subject.cluster).to eq(cluster) # until we stop double writing in 12.9: https://gitlab.com/gitlab-org/gitlab/issues/202628
          expect(subject.deployment_cluster.cluster).to eq(cluster)
        end

        context 'when a custom namespace is given' do
          let(:kubernetes_options) { { kubernetes: { namespace: 'the-custom-namespace' } } }

          context 'when cluster is managed' do
            it 'does not set the custom namespace' do
              expect(subject.deployment_cluster.kubernetes_namespace).not_to eq('the-custom-namespace')
            end
          end

          context 'when cluster is not managed' do
            let(:managed_cluster) { false }

            it 'sets the custom namespace' do
              expect(subject.deployment_cluster.kubernetes_namespace).to eq('the-custom-namespace')
            end
          end
        end
      end

      context 'when build already has deployment' do
        let!(:build) { create(:ci_build, :with_deployment, project: project, environment: 'production') }
        let!(:environment) {}

        it 'returns the persisted deployment' do
          expect { subject }.not_to change { Deployment.count }

          is_expected.to eq(build.deployment)
        end
      end
    end

    context 'when build does not start environment' do
      where(:action) do
        %w[stop prepare verify access]
      end

      with_them do
        let!(:build) do
          create(:ci_build, environment: 'production', project: project,
                            options: { environment: { name: 'production', action: action } })
        end

        it 'returns nothing' do
          is_expected.to be_nil
        end
      end
    end

    context 'when build does not have environment attribute' do
      let!(:build) { create(:ci_build, project: project) }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end
end

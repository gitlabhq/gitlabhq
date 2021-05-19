# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Deployment do
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
           sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
  end

  let(:job) { build(:ci_build, project: project, pipeline: pipeline) }
  let(:environment) { Gitlab::Ci::Pipeline::Seed::Environment.new(job).to_resource }
  let(:seed) { described_class.new(job, environment) }
  let(:attributes) { {} }

  before do
    job.assign_attributes(**attributes)
  end

  describe '#to_resource' do
    subject { seed.to_resource }

    context 'when job has environment attribute' do
      let(:attributes) do
        {
          environment: 'production',
          options: { environment: { name: 'production', **kubernetes_options } }
        }
      end

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

      context 'when environment has an invalid URL' do
        let(:attributes) do
          {
            environment: '!!!',
            options: { environment: { name: '!!!' } }
          }
        end

        it 'returns nothing' do
          is_expected.to be_nil
        end
      end

      context 'when job has already deployment' do
        let(:job) { build(:ci_build, :with_deployment, project: project, environment: 'production') }

        it 'returns the persisted deployment' do
          is_expected.to eq(job.deployment)
        end
      end
    end

    context 'when job has environment attribute with stop action' do
      let(:attributes) do
        {
          environment: 'production',
          options: { environment: { name: 'production', action: 'stop' } }
        }
      end

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end

    context 'when job has environment attribute with prepare action' do
      let(:attributes) do
        {
          environment: 'production',
          options: { environment: { name: 'production', action: 'prepare' } }
        }
      end

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end

    context 'when job does not have environment attribute' do
      let(:attributes) { { name: 'test' } }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end
end

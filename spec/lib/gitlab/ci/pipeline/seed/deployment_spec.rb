# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Deployment do
  let_it_be(:project) { create(:project, :repository) }
  let(:pipeline) do
    create(:ci_pipeline, project: project,
           sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
  end

  let(:job) { build(:ci_build, project: project, pipeline: pipeline) }
  let(:seed) { described_class.new(job) }
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
          options: { environment: { name: 'production' } }
        }
      end

      it 'returns a deployment object with environment' do
        expect(subject).to be_a(Deployment)
        expect(subject.iid).to be_present
        expect(subject.environment.name).to eq('production')
        expect(subject.cluster).to be_nil
      end

      context 'when environment has deployment platform' do
        let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

        it 'returns a deployment with cluster id' do
          expect(subject.cluster).to eq(cluster)
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
  end
end

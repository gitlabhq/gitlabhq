# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Quota::Deployments do
  let_it_be_with_refind(:namespace) { create(:namespace) }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: namespace) }
  let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }

  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

  let(:pipeline_seed) { double(:pipeline_seed, deployments_count: 2) }

  let(:command) do
    double(:command,
      project: project,
      pipeline_seed: pipeline_seed,
      save_incompleted: true
    )
  end

  let(:ci_pipeline_deployments_limit) { 0 }

  before do
    plan_limits.update!(ci_pipeline_deployments: ci_pipeline_deployments_limit)
  end

  subject(:quota) { described_class.new(namespace, pipeline, command) }

  shared_context 'limit exceeded' do
    let(:ci_pipeline_deployments_limit) { 1 }
  end

  shared_context 'limit not exceeded' do
    let(:ci_pipeline_deployments_limit) { 2 }
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      let(:ci_pipeline_deployments_limit) { 10 }

      it 'is enabled' do
        expect(quota).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      let(:ci_pipeline_deployments_limit) { 0 }

      it 'is not enabled' do
        expect(quota).not_to be_enabled
      end
    end

    context 'when limit does not exist' do
      before do
        allow(namespace).to receive(:actual_plan) { create(:default_plan) }
      end

      it 'is enabled by default' do
        expect(quota).to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'limit exceeded'

      it 'is exceeded' do
        expect(quota).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'limit not exceeded'

      it 'is not exceeded' do
        expect(quota).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'limit exceeded'

      it 'returns info about pipeline deployment limit exceeded' do
        expect(quota.message)
          .to eq "Pipeline has too many deployments! Requested 2, but the limit is 1."
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Quota::Size, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, :default_plan) }

  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

  let(:command) do
    instance_double(::Gitlab::Ci::Pipeline::Chain::Command, pipeline_seed: pipeline_seed_double)
  end

  let(:pipeline_seed_double) do
    instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2)
  end

  subject { described_class.new(namespace, pipeline, command) }

  shared_context 'when pipeline size limit exceeded' do
    before do
      plan_limits.update!(ci_pipeline_size: 1)
    end
  end

  shared_context 'when pipeline size limit not exceeded' do
    before do
      plan_limits.update!(ci_pipeline_size: 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        plan_limits.update!(ci_pipeline_size: 10)
      end

      it 'is enabled' do
        is_expected.to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        plan_limits.update!(ci_pipeline_size: 0)
      end

      it 'is not enabled' do
        is_expected.not_to be_enabled
      end
    end

    context 'when limit does not exist' do
      before do
        allow(namespace).to receive(:actual_plan) { create(:default_plan) }
      end

      it 'is not enabled' do
        is_expected.not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'when pipeline size limit exceeded'

      it 'is exceeded' do
        is_expected.to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'when pipeline size limit not exceeded'

      it 'is not exceeded' do
        is_expected.not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'when pipeline size limit exceeded'

      it 'returns info about pipeline size limit exceeded' do
        is_expected.to have_attributes(message: "The number of jobs has exceeded the limit of 1. " \
                                         "Try splitting the configuration with parent-child-pipelines " \
                                         "http://localhost/help/ci/debugging.md#pipeline-with-many-jobs-fails-to-start")
      end
    end
  end

  describe '#log_exceeded_limit?' do
    context 'when there are more than 2000 jobs in the pipeline' do
      let(:command) do
        instance_double(::Gitlab::Ci::Pipeline::Chain::Command, pipeline_seed: pipeline_seed_double)
      end

      let(:pipeline_seed_double) do
        instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2001)
      end

      it 'returns true' do
        is_expected.to be_log_exceeded_limit
      end
    end

    context 'when there are 2000 or less jobs in the pipeline' do
      let(:command) do
        instance_double(::Gitlab::Ci::Pipeline::Chain::Command, pipeline_seed: pipeline_seed_double)
      end

      let(:pipeline_seed_double) do
        instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2000)
      end

      it 'returns false' do
        is_expected.not_to be_log_exceeded_limit
      end
    end
  end
end

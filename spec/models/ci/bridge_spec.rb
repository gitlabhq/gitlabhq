# frozen_string_literal: true

require 'spec_helper'

describe Ci::Bridge do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, pipeline: pipeline)
  end

  it { is_expected.to include_module(Ci::PipelineDelegator) }

  describe '#tags' do
    it 'only has a bridge tag' do
      expect(bridge.tags).to eq [:bridge]
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }
    let(:status) { bridge.detailed_status(user) }

    it 'returns detailed status object' do
      expect(status).to be_a Gitlab::Ci::Status::Success
    end
  end

  describe '#scoped_variables_hash' do
    it 'returns a hash representing variables' do
      variables = %w[
        CI_JOB_NAME CI_JOB_STAGE CI_COMMIT_SHA CI_COMMIT_SHORT_SHA
        CI_COMMIT_BEFORE_SHA CI_COMMIT_REF_NAME CI_COMMIT_REF_SLUG
        CI_PROJECT_ID CI_PROJECT_NAME CI_PROJECT_PATH
        CI_PROJECT_PATH_SLUG CI_PROJECT_NAMESPACE CI_PIPELINE_IID
        CI_CONFIG_PATH CI_PIPELINE_SOURCE CI_COMMIT_MESSAGE
        CI_COMMIT_TITLE CI_COMMIT_DESCRIPTION CI_COMMIT_REF_PROTECTED
      ]

      expect(bridge.scoped_variables_hash.keys).to include(*variables)
    end
  end
end

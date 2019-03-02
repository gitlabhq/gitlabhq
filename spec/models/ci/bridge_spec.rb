require 'spec_helper'

describe Ci::Bridge do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, pipeline: pipeline)
  end

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
      expect(bridge.scoped_variables_hash.keys).to eq %w[
        CI GITLAB_CI GITLAB_FEATURES CI_SERVER_NAME
        CI_SERVER_VERSION CI_SERVER_VERSION_MAJOR
        CI_SERVER_VERSION_MINOR CI_SERVER_VERSION_PATCH
        CI_SERVER_REVISION CI_JOB_NAME CI_JOB_STAGE
        CI_COMMIT_SHA CI_COMMIT_SHORT_SHA CI_COMMIT_BEFORE_SHA
        CI_COMMIT_REF_NAME CI_COMMIT_REF_SLUG CI_NODE_TOTAL
        CI_BUILD_REF CI_BUILD_BEFORE_SHA CI_BUILD_REF_NAME
        CI_BUILD_REF_SLUG CI_BUILD_NAME CI_BUILD_STAGE
        CI_PROJECT_ID CI_PROJECT_NAME CI_PROJECT_PATH
        CI_PROJECT_PATH_SLUG CI_PROJECT_NAMESPACE CI_PROJECT_URL
        CI_PROJECT_VISIBILITY CI_PAGES_DOMAIN CI_PAGES_URL
        CI_REGISTRY CI_REGISTRY_IMAGE CI_API_V4_URL
        CI_PIPELINE_IID CI_CONFIG_PATH CI_PIPELINE_SOURCE
        CI_COMMIT_MESSAGE CI_COMMIT_TITLE CI_COMMIT_DESCRIPTION
      ]
    end
  end
end

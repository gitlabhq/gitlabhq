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
end

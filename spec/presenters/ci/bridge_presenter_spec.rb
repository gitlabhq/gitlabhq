require 'spec_helper'

describe Ci::BridgePresenter do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }
  set(:bridge) { create(:ci_bridge, pipeline: pipeline, status: :failed) }

  subject(:presenter) do
    described_class.new(bridge)
  end

  it 'presents information about recoverable state' do
    expect(presenter).to be_recoverable
  end
end

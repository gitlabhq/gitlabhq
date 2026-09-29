# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BridgePresenter do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }
  let(:bridge) { build_stubbed(:ci_bridge, pipeline: pipeline, status: :failed, user: user) }

  subject(:presenter) do
    described_class.new(bridge)
  end

  it 'presents information about recoverable state' do
    expect(presenter).to be_recoverable
  end

  it 'presents the detailed status for the user' do
    expect(bridge).to receive(:detailed_status).with(user)

    presenter.detailed_status
  end
end

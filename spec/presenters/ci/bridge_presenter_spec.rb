# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BridgePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline, status: :failed, user: user) }

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

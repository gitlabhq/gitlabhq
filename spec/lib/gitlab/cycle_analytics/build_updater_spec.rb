require 'spec_helper'

describe Gitlab::CycleAnalytics::BuildUpdater do
  let(:build) { create(:ci_build) }
  let(:events) { [{ 'id' => build.id }] }

  it 'maps the correct build' do
    described_class.update!(events)

    expect(events.first['build']).to eq(build)
  end
end

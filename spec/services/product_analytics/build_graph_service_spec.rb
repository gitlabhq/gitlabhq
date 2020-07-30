# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::BuildGraphService do
  let_it_be(:project) { create(:project) }

  let_it_be(:events) do
    [
      create(:product_analytics_event, project: project, platform: 'web'),
      create(:product_analytics_event, project: project, platform: 'web'),
      create(:product_analytics_event, project: project, platform: 'app'),
      create(:product_analytics_event, project: project, platform: 'mobile'),
      create(:product_analytics_event, project: project, platform: 'mobile', collector_tstamp: Time.zone.now - 60.days)
    ]
  end

  let(:params) { { graph: 'platform', timerange: 5 } }

  subject { described_class.new(project, params).execute }

  it 'returns a valid graph hash' do
    expect(subject[:id]).to eq(:platform)
    expect(subject[:keys]).to eq(%w(app mobile web))
    expect(subject[:values]).to eq([1, 1, 2])
  end
end

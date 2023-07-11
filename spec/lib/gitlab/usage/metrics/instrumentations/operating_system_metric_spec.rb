# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::OperatingSystemMetric, feature_category: :service_ping do
  let(:ohai_data) { { "platform" => "ubuntu", "platform_version" => "20.04" } }
  let(:expected_value) { 'ubuntu-20.04' }

  before do
    allow_next_instance_of(Ohai::System) do |ohai|
      allow(ohai).to receive(:data).and_return(ohai_data)
    end
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }

  context 'when on Debian with armv architecture' do
    let(:ohai_data) { { "platform" => "debian", "platform_version" => "10", 'kernel' => { 'machine' => 'armv' } } }
    let(:expected_value) { 'raspbian-10' }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end

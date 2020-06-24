# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIdeTerminalEntity do
  let(:build) { create(:ci_build) }
  let(:entity) { described_class.new(WebIdeTerminal.new(build)) }

  subject { entity.as_json }

  it { is_expected.to have_key(:id) }
  it { is_expected.to have_key(:status) }
  it { is_expected.to have_key(:show_path) }
  it { is_expected.to have_key(:cancel_path) }
  it { is_expected.to have_key(:retry_path) }
  it { is_expected.to have_key(:terminal_path) }
  it { is_expected.to have_key(:services) }
  it { is_expected.to have_key(:proxy_websocket_path) }

  context 'when feature flag build_service_proxy is disabled' do
    before do
      stub_feature_flags(build_service_proxy: false)
    end

    it { is_expected.not_to have_key(:proxy_websocket_path) }
  end
end

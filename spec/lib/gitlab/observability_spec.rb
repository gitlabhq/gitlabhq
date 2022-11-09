# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Observability do
  describe '.observability_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_url }

    before do
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end
end

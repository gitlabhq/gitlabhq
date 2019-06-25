# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::LetsEncrypt do
  include LetsEncryptHelpers

  before do
    stub_lets_encrypt_settings
  end

  describe '.enabled?' do
    let(:project) { create(:project) }
    let(:pages_domain) { create(:pages_domain, project: project) }

    subject { described_class.enabled?(pages_domain) }

    context 'when terms of service are accepted' do
      it { is_expected.to eq(true) }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(pages_auto_ssl: false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when terms of service are not accepted' do
      before do
        stub_application_setting(lets_encrypt_terms_of_service_accepted: false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when feature flag for project is disabled' do
      before do
        stub_feature_flags(pages_auto_ssl_for_project: false)
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when domain has not project' do
      let(:pages_domain) { create(:pages_domain) }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end
end

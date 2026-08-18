# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::ProviderSignInRedirect, feature_category: :system_access do
  let(:redirector) { Authn::ChatGpt::SiwcRedirect }
  let(:request) { instance_double(ActionDispatch::Request) }

  describe '.enabled?' do
    subject(:enabled) { described_class.enabled?(provider) }

    context 'with a registered provider' do
      let(:provider) { redirector::PROVIDER }

      it 'delegates to the matching redirector' do
        expect(redirector).to receive(:enabled?).and_return(true)

        expect(enabled).to be(true)
      end

      it 'returns false when the redirector is disabled' do
        expect(redirector).to receive(:enabled?).and_return(false)

        expect(enabled).to be(false)
      end
    end

    context 'with an unregistered provider' do
      let(:provider) { 'ldapmain' }

      it { is_expected.to be(false) }
    end

    context 'with a nil provider' do
      let(:provider) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe '.provider_for_target_flow' do
    subject(:provider_for_target_flow) { described_class.provider_for_target_flow(target_flow, request) }

    context 'with a registered target flow' do
      let(:target_flow) { redirector::TARGET_FLOW }

      context 'when the redirector is enabled and the request is trusted' do
        before do
          allow(redirector).to receive(:enabled?).and_return(true)
          allow(redirector).to receive(:trusted_request?).with(request).and_return(true)
        end

        it { is_expected.to eq(redirector::PROVIDER) }
      end

      context 'when the redirector is disabled' do
        before do
          allow(redirector).to receive(:enabled?).and_return(false)
        end

        it 'does not validate the request origin' do
          expect(redirector).not_to receive(:trusted_request?)

          expect(provider_for_target_flow).to be_nil
        end
      end

      context 'when the request is not trusted' do
        before do
          allow(redirector).to receive(:enabled?).and_return(true)
          allow(redirector).to receive(:trusted_request?).with(request).and_return(false)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'with an unregistered target flow' do
      let(:target_flow) { 'something_else' }

      it { is_expected.to be_nil }
    end

    context 'with a nil target flow' do
      let(:target_flow) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '.redirector_for_provider' do
    it 'returns the matching redirector' do
      expect(described_class.redirector_for_provider(redirector::PROVIDER)).to eq(redirector)
    end

    it 'returns nil for an unregistered provider' do
      expect(described_class.redirector_for_provider('ldapmain')).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Middleware::IpAddress, feature_category: :system_access do
  let(:app) { double(:app) } # rubocop:disable RSpec/VerifiedDoubles -- stubbed app
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }

  describe '#call' do
    before do
      allow(env).to receive(:[]).with('action_dispatch.remote_ip').and_return('127.0.0.1')
      allow(env).to receive(:[]).with('PATH_INFO').and_return('/api/v4/groups')
    end

    it 'calls ip address state to set the address' do
      expect(::Gitlab::IpAddressState).to receive(:set_address).with('127.0.0.1')
      expect(app).to receive(:call)

      middleware.call(env)
    end

    it 'calls ip address state to nullify the address' do
      expect(::Gitlab::IpAddressState).to receive(:nullify_address)
      expect(app).to receive(:call)

      middleware.call(env)
    end

    it 'calls ip address state to nullify the address when app raises an error' do
      expect(::Gitlab::IpAddressState).to receive(:nullify_address)
      expect(app).to receive(:call).and_raise('boom')

      expect { middleware.call(env) }.to raise_error('boom')
    end

    context 'when it is internal endpoint' do
      before do
        allow(env).to receive(:[]).with('PATH_INFO').and_return('/api/v4/internal/allowed')
      end

      it 'does not call ip address state to set the address' do
        expect(::Gitlab::IpAddressState).not_to receive(:with)
        expect(app).to receive(:call)

        middleware.call(env)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ServiceDeskEmail do
  describe '.enabled?' do
    context 'when service_desk_email is enabled and address is set' do
      before do
        stub_service_desk_email_setting(enabled: true, address: 'foo')
      end

      it 'returns true' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'when service_desk_email is disabled' do
      before do
        stub_service_desk_email_setting(enabled: false, address: 'foo')
      end

      it 'returns false' do
        expect(described_class.enabled?).to be_falsey
      end
    end

    context 'when service desk address is not set' do
      before do
        stub_service_desk_email_setting(enabled: true, address: nil)
      end

      it 'returns false' do
        expect(described_class.enabled?).to be_falsey
      end
    end
  end

  describe '.key_from_address' do
    context 'when service desk address is set' do
      before do
        stub_service_desk_email_setting(address: 'address+%{key}@example.com')
      end

      it 'returns key' do
        expect(described_class.key_from_address('address+key@example.com')).to eq('key')
      end
    end

    context 'when service desk address is not set' do
      before do
        stub_service_desk_email_setting(address: nil)
      end

      it 'returns nil' do
        expect(described_class.key_from_address('address+key@example.com')).to be_nil
      end
    end
  end

  describe '.address_for_key' do
    context 'when service desk address is set' do
      before do
        stub_service_desk_email_setting(address: 'address+%{key}@example.com')
      end

      it 'returns address' do
        expect(described_class.address_for_key('foo')).to eq('address+foo@example.com')
      end
    end

    context 'when service desk address is not set' do
      before do
        stub_service_desk_email_setting(address: nil)
      end

      it 'returns nil' do
        expect(described_class.key_from_address('foo')).to be_nil
      end
    end
  end
end

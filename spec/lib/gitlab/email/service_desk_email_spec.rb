# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDeskEmail, feature_category: :service_desk do
  let(:setting_name) { :service_desk_email }

  it_behaves_like 'common email methods'

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

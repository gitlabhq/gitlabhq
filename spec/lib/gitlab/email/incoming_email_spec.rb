# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::IncomingEmail, feature_category: :service_desk do
  let(:setting_name) { :incoming_email }

  it_behaves_like 'common email methods'

  describe 'self.key_from_address' do
    before do
      stub_incoming_email_setting(address: 'replies+%{key}@example.com')
    end

    it "returns reply key" do
      expect(described_class.key_from_address("replies+key@example.com")).to eq("key")
    end

    it 'does not match emails with extra bits' do
      expect(described_class.key_from_address('somereplies+somekey@example.com.someotherdomain.com')).to be nil
    end

    context 'when a custom wildcard address is used' do
      let(:wildcard_address) { 'custom.address+%{key}@example.com' }

      it 'finds key if email matches address pattern' do
        key = described_class.key_from_address(
          'custom.address+foo@example.com', wildcard_address: wildcard_address
        )
        expect(key).to eq('foo')
      end
    end
  end
end

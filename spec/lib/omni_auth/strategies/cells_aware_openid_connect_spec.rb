# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe OmniAuth::Strategies::CellsAwareOpenidConnect, feature_category: :system_access do
  subject(:strategy) { described_class.new({}) }

  it 'is a subclass of OpenIDConnect' do
    expect(strategy).to be_a_kind_of(OmniAuth::Strategies::OpenIDConnect)
  end

  describe '#user_info' do
    it 'returns user info from the decoded id_token' do
      payload = { sub: '12345', email: 'user@example.com', name: 'Test User' }
      allow(strategy).to receive(:decode_id_token).and_return(
        instance_double(OpenIDConnect::ResponseObject::IdToken, raw_attributes: payload)
      )
      allow(strategy).to receive_message_chain(:access_token, :id_token).and_return('token')

      user_info = strategy.user_info

      expect(user_info.sub).to eq('12345')
      expect(user_info.email).to eq('user@example.com')
      expect(user_info.name).to eq('Test User')
    end
  end
end

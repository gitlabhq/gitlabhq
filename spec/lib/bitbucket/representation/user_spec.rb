# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::User, feature_category: :importers do
  let(:display_name) { 'Jonathan Doe' }
  let(:nickname) { 'Jon Doe' }
  let(:account_id) { '123456:abcdefgh-1234-5678-9012-abcdefghijkl' }
  let(:current_user_object) { { 'username' => 'Ben' } }
  let(:other_user_object) do
    {
      'user' => {
        'display_name' => display_name,
        'nickname' => nickname,
        'account_id' => account_id
      }
    }
  end

  describe '#username' do
    it 'returns correct value' do
      user = described_class.new(current_user_object)

      expect(user.username).to eq('Ben')
    end
  end

  describe '#account_id' do
    it 'returns correct value' do
      user = described_class.new(other_user_object)

      expect(user.account_id).to eq(account_id)
    end
  end

  describe '#name' do
    it 'returns correct value' do
      user = described_class.new(other_user_object)

      expect(user.name).to eq(display_name)
    end
  end

  describe '#nickname' do
    it 'returns correct value' do
      user = described_class.new(other_user_object)

      expect(user.nickname).to eq(nickname)
    end
  end
end

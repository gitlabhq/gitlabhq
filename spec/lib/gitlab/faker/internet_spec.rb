# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Faker::Internet, feature_category: :shared do
  describe '.unique_username' do
    let(:valid_username) { 'valid_user' }
    let(:invalid_username) { 'user.diff' }

    it 'returns a unique username' do
      allow(FFaker::Internet.unique).to receive(:user_name).and_return(valid_username)

      expect(described_class.unique_username).to eq(valid_username)
    end

    it 'retries when a reserved username is generated' do
      allow(FFaker::Internet.unique).to receive(:user_name).and_return(invalid_username, valid_username)

      expect(described_class.unique_username).to eq(valid_username)

      expect(FFaker::Internet.unique).to have_received(:user_name).exactly(2).times
    end

    it 'respects the MAX_TRIES constant' do
      stub_const("#{described_class}::MAX_TRIES", 1)
      allow(FFaker::Internet.unique).to receive(:user_name).and_return(invalid_username)

      expect { described_class.unique_username }
        .to raise_error(FFaker::UniqueUtils::RetryLimitExceeded, "Retry limit exceeded for unique_username")
    end
  end
end

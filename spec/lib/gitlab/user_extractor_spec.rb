# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UserExtractor do
  let(:text) do
    <<~TXT
    This is a long texth that mentions some users.
    @user-1, @user-2 and user@gitlab.org take a walk in the park.
    There they meet @user-4 that was out with other-user@gitlab.org.
    @user-1 thought it was late, so went home straight away
    TXT
  end
  subject(:extractor) { described_class.new(text) }

  describe '#users' do
    it 'returns an empty relation when nil was passed' do
      extractor = described_class.new(nil)

      expect(extractor.users).to be_empty
      expect(extractor.users).to be_a(ActiveRecord::Relation)
    end

    it 'returns the user case insensitive for usernames' do
      user = create(:user, username: "USER-4")

      expect(extractor.users).to include(user)
    end

    it 'returns users by primary email' do
      user = create(:user, email: 'user@gitlab.org')

      expect(extractor.users).to include(user)
    end

    it 'returns users by secondary email' do
      user = create(:email, email: 'other-user@gitlab.org').user

      expect(extractor.users).to include(user)
    end
  end

  describe '#matches' do
    it 'includes all mentioned email adresses' do
      expect(extractor.matches[:emails]).to contain_exactly('user@gitlab.org', 'other-user@gitlab.org')
    end

    it 'includes all mentioned usernames' do
      expect(extractor.matches[:usernames]).to contain_exactly('user-1', 'user-2', 'user-4')
    end
  end

  describe '#references' do
    it 'includes all user-references once' do
      expect(extractor.references).to contain_exactly('user-1', 'user-2', 'user@gitlab.org', 'user-4', 'other-user@gitlab.org')
    end
  end
end

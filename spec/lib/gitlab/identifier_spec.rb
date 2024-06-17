# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Identifier do
  let(:identifier) do
    Class.new { include Gitlab::Identifier }.new
  end

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }

  describe '#identify' do
    context 'without an identifier' do
      it 'returns nil' do
        expect(identifier.identify('')).to be nil
      end
    end

    context 'with a user identifier' do
      it 'identifies the user using a user ID' do
        expect(identifier).to receive(:identify_using_user)
          .with("user-#{user.id}")

        identifier.identify("user-#{user.id}")
      end
    end

    context 'with an SSH key identifier' do
      it 'identifies the user using an SSH key ID' do
        expect(identifier).to receive(:identify_using_ssh_key)
          .with("key-#{key.id}")

        identifier.identify("key-#{key.id}")
      end
    end
  end

  describe '#identify_using_user' do
    it 'returns the User for an existing ID in the identifier' do
      found = identifier.identify_using_user("user-#{user.id}")

      expect(found).to eq(user)
    end

    it 'returns nil for a non existing user ID' do
      found = identifier.identify_using_user('user--1')

      expect(found).to be_nil
    end

    it 'caches the found users per ID' do
      expect(User).to receive(:find_by).once.and_call_original

      2.times do
        found = identifier.identify_using_user("user-#{user.id}")

        expect(found).to eq(user)
      end
    end
  end

  describe '#identify_using_ssh_key' do
    it 'returns the User for an existing SSH key' do
      found = identifier.identify_using_ssh_key("key-#{key.id}")

      expect(found).to eq(user)
    end

    it 'returns nil for an invalid SSH key' do
      found = identifier.identify_using_ssh_key('key--1')

      expect(found).to be_nil
    end

    it 'caches the found users per key' do
      expect(User).to receive(:find_by_ssh_key_id).once.and_call_original

      2.times do
        found = identifier.identify_using_ssh_key("key-#{key.id}")

        expect(found).to eq(user)
      end
    end

    context 'when key id is for a deploy key' do
      let(:key) { create(:deploy_key, user: user) }

      it 'returns nil' do
        found = identifier.identify_using_ssh_key("key-#{key.id}")

        expect(found).to be_nil
      end
    end
  end
end

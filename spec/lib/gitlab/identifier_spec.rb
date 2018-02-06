require 'spec_helper'

describe Gitlab::Identifier do
  let(:identifier) do
    Class.new { include Gitlab::Identifier }.new
  end

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }

  describe '#identify' do
    context 'without an identifier' do
      it 'identifies the user using a commit' do
        expect(identifier).to receive(:identify_using_commit)
          .with(project, '123')

        identifier.identify('', project, '123')
      end
    end

    context 'with a user identifier' do
      it 'identifies the user using a user ID' do
        expect(identifier).to receive(:identify_using_user)
          .with("user-#{user.id}")

        identifier.identify("user-#{user.id}", project, '123')
      end
    end

    context 'with an SSH key identifier' do
      it 'identifies the user using an SSH key ID' do
        expect(identifier).to receive(:identify_using_ssh_key)
          .with("key-#{key.id}")

        identifier.identify("key-#{key.id}", project, '123')
      end
    end
  end

  describe '#identify_using_commit' do
    it "returns the User for an existing commit author's Email address" do
      commit = double(:commit, author: user, author_email: user.email)

      expect(project).to receive(:commit).with('123').and_return(commit)

      expect(identifier.identify_using_commit(project, '123')).to eq(user)
    end

    it 'returns nil when no user could be found' do
      allow(project).to receive(:commit).with('123').and_return(nil)

      expect(identifier.identify_using_commit(project, '123')).to be_nil
    end

    it 'returns nil when the commit does not have an author Email' do
      commit = double(:commit, author_email: nil)

      expect(project).to receive(:commit).with('123').and_return(commit)

      expect(identifier.identify_using_commit(project, '123')).to be_nil
    end

    it 'caches the found users per Email' do
      commit = double(:commit, author: user, author_email: user.email)

      expect(project).to receive(:commit).with('123').twice.and_return(commit)

      2.times do
        expect(identifier.identify_using_commit(project, '123')).to eq(user)
      end
    end

    it 'returns nil if the project & ref are not present' do
      expect(identifier.identify_using_commit(nil, nil)).to be_nil
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
  end
end

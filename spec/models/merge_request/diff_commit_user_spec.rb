# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::DiffCommitUser, feature_category: :code_review_workflow do
  let_it_be(:organization_id) { create(:organization, id: 1).id }

  describe 'validations' do
    it 'requires that names are less than 512 characters long' do
      user = build(:merge_request_diff_commit_user, name: 'a' * 1000)
      expect(user).not_to be_valid
    end

    it 'requires that Emails are less than 512 characters long' do
      user = build(:merge_request_diff_commit_user, email: 'a' * 1000)
      expect(user).not_to be_valid
    end

    it 'requires either a name or Email' do
      user = build(:merge_request_diff_commit_user, name: nil, email: nil)
      expect(user).not_to be_valid
    end

    it 'allows setting of just a name' do
      user = build(:merge_request_diff_commit_user, email: nil)
      expect(user).to be_valid
    end

    it 'allows setting of just an Email' do
      user = build(:merge_request_diff_commit_user, name: nil)
      expect(user).to be_valid
    end

    it 'allows setting of both a name and Email' do
      user = build(:merge_request_diff_commit_user)
      expect(user).to be_valid
    end
  end

  describe '.prepare' do
    it 'trims a value to at most 512 characters' do
      expect(described_class.prepare('€' * 1_000)).to eq('€' * 512)
    end

    it 'returns nil if the value is an empty string' do
      expect(described_class.prepare('')).to be_nil
    end
  end

  describe '.find_or_create' do
    context 'when with_organization is true' do
      it 'creates a new row if none exist' do
        alice = described_class.find_or_create('Alice', 'alice@example.com', organization_id, with_organization: true)
        expect(alice.name).to eq('Alice')
        expect(alice.email).to eq('alice@example.com')
        expect(alice.organization_id).to eq(organization_id)
      end

      it 'returns an existing row if one exists' do
        user1 = create(:merge_request_diff_commit_user, organization_id: organization_id)
        user2 = described_class.find_or_create(user1.name, user1.email, organization_id, with_organization: true)
        expect(user1).to eq(user2)
      end

      it 'handles concurrent inserts' do
        user = create(:merge_request_diff_commit_user, organization_id: organization_id)

        # Stub find_by to always return nil to force the find_or_create_by! path
        expect(described_class)
          .to receive(:find_by)
          .with(name: user.name, email: user.email, organization_id: organization_id)
          .and_return(nil)

        # If organization_id is present, expect a second find_by
        expect(described_class)
          .to receive(:find_by)
          .with(name: user.name, email: user.email, organization_id: nil)
          .and_return(nil)

        # Now expect find_or_create_by! to be called and raise the error
        expect(described_class)
          .to receive(:find_or_create_by!)
          .ordered
          .with(name: user.name, email: user.email, organization_id: organization_id)
          .and_raise(ActiveRecord::RecordNotUnique)

        # On retry, the first find_by should succeed
        expect(described_class)
          .to receive(:find_by)
          .with(name: user.name, email: user.email, organization_id: organization_id)
          .and_return(user)

        expect(described_class.find_or_create(user.name, user.email, organization_id,
          with_organization: true)).to eq(user)
      end
    end

    context 'when with_organization is false (default)' do
      it 'creates a new row with default organization_id' do
        alice = described_class.find_or_create('Alice', 'alice@example.com', organization_id)
        expect(alice.name).to eq('Alice')
        expect(alice.email).to eq('alice@example.com')
        expect(alice.organization_id).to eq(organization_id)
      end

      it 'returns an existing row without considering organization_id' do
        user1 = create(:merge_request_diff_commit_user,
          name: 'Bob',
          email: 'bob@example.com',
          organization_id: organization_id)

        user2 = described_class.find_or_create('Bob', 'bob@example.com', organization_id)
        expect(user1).to eq(user2)
      end

      it 'sets organization_id parameter for new records' do
        alice = described_class.find_or_create('Alice', 'alice@example.com', organization_id)
        expect(alice.organization_id).to eq(organization_id)
      end

      it 'returns an existing row even if it has organization_id set' do
        # Record created when feature flag was enabled
        user1 = create(:merge_request_diff_commit_user,
          name: 'Charlie',
          email: 'charlie@example.com',
          organization_id: organization_id)

        # Finding the record after feature flag is disabled
        user2 = described_class.find_or_create('Charlie', 'charlie@example.com', organization_id)

        expect(user2).to eq(user1)
        expect(user2.organization_id).to eq(organization_id)
      end
    end
  end

  describe '.bulk_find' do
    context 'when with_organization is true' do
      it 'finds records using organization_id' do
        user = create(:merge_request_diff_commit_user, organization_id: organization_id)
        non_matching_user = create(:merge_request_diff_commit_user, organization_id: create(:organization).id)

        triples = [[user.name, user.email, organization_id]]

        results = described_class.bulk_find(triples, with_organization: true)
        expect(results).to include(user)
        expect(results).not_to include(non_matching_user)
      end
    end

    context 'when with_organization is false' do
      it 'finds records without using organization_id' do
        user = create(:merge_request_diff_commit_user, name: 'Alice', email: 'alice@example.com',
          organization_id: organization_id)
        non_matching_user = create(:merge_request_diff_commit_user, name: 'Bob', email: 'bob@example.com')

        pairs = [['Alice', 'alice@example.com', organization_id]] # organization_id is ignored

        results = described_class.bulk_find(pairs)
        expect(results).to include(user)
        expect(results).not_to include(non_matching_user)
      end
    end
  end

  describe '.bulk_find_or_create' do
    context 'when with_organization is true' do
      it 'bulk creates missing rows and reuses existing rows' do
        bob = create(
          :merge_request_diff_commit_user,
          name: 'Bob',
          email: 'bob@example.com',
          organization_id: organization_id
        )

        triples = [
          ['Alice', 'alice@example.com', organization_id],
          ['Bob', 'bob@example.com', organization_id]
        ]

        users = described_class.bulk_find_or_create(triples, with_organization: true)

        alice = described_class.find_by(name: 'Alice', email: 'alice@example.com', organization_id: organization_id)
        expect(users[['Alice', 'alice@example.com', organization_id]]).to eq(alice)
        expect(users[['Bob', 'bob@example.com', organization_id]]).to eq(bob)
        expect(alice.organization_id).to eq(organization_id)
      end

      it 'does not insert any data when all users exist' do
        bob = create(
          :merge_request_diff_commit_user,
          name: 'Bob',
          email: 'bob@example.com',
          organization_id: organization_id
        )

        triples = [['Bob', 'bob@example.com', organization_id]]

        # Mock to verify insert_all isn't called
        expect(described_class).not_to receive(:insert_all)

        users = described_class.bulk_find_or_create(triples, with_organization: true)
        expect(users[['Bob', 'bob@example.com', organization_id]]).to eq(bob)
      end

      it 'handles concurrently inserted rows' do
        bob = create(
          :merge_request_diff_commit_user,
          name: 'Bob',
          email: 'bob@example.com',
          organization_id: organization_id
        )

        triples = [['Bob', 'bob@example.com', organization_id]]

        # First call: initial bulk_find with with_organization: false
        expect(described_class)
          .to receive(:bulk_find)
          .with(triples, with_organization: false)
          .and_return([])

        # Mock insert_all to return empty array (simulating concurrent insert happened)
        expect(described_class)
          .to receive(:insert_all)
          .and_return([])

        # Final call: checking for concurrent inserts with with_organization: true
        expect(described_class)
          .to receive(:bulk_find)
          .with(triples, with_organization: true)
          .and_return([bob])

        users = described_class.bulk_find_or_create(triples, with_organization: true)
        expect(users[['Bob', 'bob@example.com', organization_id]]).to eq(bob)
      end

      it 'assigns organization_id to all created records' do
        triples = [
          ['Alice', 'alice@example.com', organization_id],
          ['Bob', 'bob@example.com', organization_id],
          ['Charlie', 'charlie@example.com', organization_id]
        ]

        users = described_class.bulk_find_or_create(triples, with_organization: true)
        expect(users.values.map(&:organization_id).uniq).to eq([organization_id])
      end
    end

    context 'when with_organization is false (default)' do
      it 'bulk creates missing rows with default organization_id' do
        bob = create(
          :merge_request_diff_commit_user,
          name: 'Bob',
          email: 'bob@example.com',
          organization_id: organization_id
        )

        # Joe was created when feature flag was enabled
        joe = create(
          :merge_request_diff_commit_user,
          name: 'Joe',
          email: 'joe@example.com',
          organization_id: organization_id
        )

        pairs = [
          ['Alice', 'alice@example.com'],
          ['Bob', 'bob@example.com'],
          ['Joe', 'joe@example.com']
        ]

        users = described_class.bulk_find_or_create(pairs)

        alice = described_class.find_by(name: 'Alice', email: 'alice@example.com')
        expect(users[['Alice', 'alice@example.com']]).to eq(alice)
        expect(users[['Bob', 'bob@example.com']]).to eq(bob)
        expect(users[['Joe', 'joe@example.com']]).to eq(joe)
        expect(alice.organization_id).to eq(organization_id)
      end

      it 'handles input with organization_id but uses provided id for new records' do
        triples = [
          ['Alice', 'alice@example.com', organization_id],
          ['Bob', 'bob@example.com', organization_id]
        ]

        users = described_class.bulk_find_or_create(triples)

        alice = described_class.find_by(name: 'Alice', email: 'alice@example.com')
        bob = described_class.find_by(name: 'Bob', email: 'bob@example.com')

        expect(users[['Alice', 'alice@example.com']]).to eq(alice)
        expect(users[['Bob', 'bob@example.com']]).to eq(bob)

        expect(alice.organization_id).to eq(organization_id)
        expect(bob.organization_id).to eq(organization_id)
      end

      it 'uses the legacy method internally' do
        pairs = [['Alice', 'alice@example.com']]

        expect(described_class).to receive(:bulk_find_or_create_legacy).with(pairs).and_call_original

        described_class.bulk_find_or_create(pairs)
      end
    end
  end
end

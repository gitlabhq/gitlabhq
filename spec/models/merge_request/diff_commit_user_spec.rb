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
    it 'creates a new row if none exist' do
      alice = described_class.find_or_create('Alice', 'alice@example.com', organization_id)
      expect(alice.name).to eq('Alice')
      expect(alice.email).to eq('alice@example.com')
      expect(alice.organization_id).to eq(organization_id)
    end

    it 'returns an existing row if one exists' do
      user1 = create(:merge_request_diff_commit_user, organization_id: organization_id)
      user2 = described_class.find_or_create(user1.name, user1.email, organization_id)
      expect(user1).to eq(user2)
    end

    it 'handles concurrent inserts' do
      user = create(:merge_request_diff_commit_user, organization_id: organization_id)

      # Now expect find_or_create_by! to be called and raise the error
      expect(described_class)
        .to receive(:find_or_create_by!)
        .with(name: user.name, email: user.email, organization_id: organization_id)
        .and_raise(ActiveRecord::RecordNotUnique)

      # On retry, find_or_create_by! should succeed
      expect(described_class)
        .to receive(:find_or_create_by!)
        .with(name: user.name, email: user.email, organization_id: organization_id)
        .and_return(user)

      expect(described_class.find_or_create(user.name, user.email, organization_id)).to eq(user)
    end
  end

  describe '.bulk_find' do
    it 'finds records using organization_id' do
      user = create(:merge_request_diff_commit_user, organization_id: organization_id)
      non_matching_user = create(:merge_request_diff_commit_user, organization_id: create(:organization).id)

      triples = [[user.name, user.email, organization_id]]

      results = described_class.bulk_find(triples)
      expect(results).to include(user)
      expect(results).not_to include(non_matching_user)
    end
  end

  describe '.bulk_find_or_create' do
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

      users = described_class.bulk_find_or_create(triples)

      alice = described_class.find_by(name: 'Alice', email: 'alice@example.com', organization_id: organization_id)
      # Now triples are keyed by triples
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

      users = described_class.bulk_find_or_create(triples)
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

      # First call: initial bulk_find for existing records
      expect(described_class)
        .to receive(:bulk_find)
        .and_return([])

      # Mock insert_all to return empty array (simulating concurrent insert happened)
      expect(described_class)
        .to receive(:insert_all)
        .and_return([])

      # Final call: checking for concurrent inserts
      expect(described_class)
        .to receive(:bulk_find)
        .with(triples)
        .and_return([bob])

      users = described_class.bulk_find_or_create(triples)
      expect(users[['Bob', 'bob@example.com', organization_id]]).to eq(bob)
    end

    it 'assigns organization_id to all created records' do
      triples = [
        ['Alice', 'alice@example.com', organization_id],
        ['Bob', 'bob@example.com', organization_id],
        ['Charlie', 'charlie@example.com', organization_id]
      ]

      users = described_class.bulk_find_or_create(triples)
      expect(users.values.map(&:organization_id).uniq).to eq([organization_id])
    end
  end
end

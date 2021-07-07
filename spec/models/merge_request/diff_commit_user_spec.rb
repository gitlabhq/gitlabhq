# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::DiffCommitUser do
  describe 'validations' do
    it 'requires that names are less than 512 characters long' do
      expect(described_class.new(name: 'a' * 1000)).not_to be_valid
    end

    it 'requires that Emails are less than 512 characters long' do
      expect(described_class.new(email: 'a' * 1000)).not_to be_valid
    end

    it 'requires either a name or Email' do
      expect(described_class.new).not_to be_valid
    end

    it 'allows setting of just a name' do
      expect(described_class.new(name: 'Alice')).to be_valid
    end

    it 'allows setting of just an Email' do
      expect(described_class.new(email: 'alice@example.com')).to be_valid
    end

    it 'allows setting of both a name and Email' do
      expect(described_class.new(name: 'Alice', email: 'alice@example.com'))
        .to be_valid
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
      alice = described_class.find_or_create('Alice', 'alice@example.com')

      expect(alice.name).to eq('Alice')
      expect(alice.email).to eq('alice@example.com')
    end

    it 'returns an existing row if one exists' do
      user1 = create(:merge_request_diff_commit_user)
      user2 = described_class.find_or_create(user1.name, user1.email)

      expect(user1).to eq(user2)
    end

    it 'handles concurrent inserts' do
      user = create(:merge_request_diff_commit_user)

      expect(described_class)
        .to receive(:find_or_create_by!)
        .ordered
        .with(name: user.name, email: user.email)
        .and_raise(ActiveRecord::RecordNotUnique)

      expect(described_class)
        .to receive(:find_or_create_by!)
        .ordered
        .with(name: user.name, email: user.email)
        .and_return(user)

      expect(described_class.find_or_create(user.name, user.email)).to eq(user)
    end
  end

  describe '.bulk_find_or_create' do
    it 'bulk creates missing rows and reuses existing rows' do
      bob = create(
        :merge_request_diff_commit_user,
        name: 'Bob',
        email: 'bob@example.com'
      )

      users = described_class.bulk_find_or_create(
        [%w[Alice alice@example.com], %w[Bob bob@example.com]]
      )
      alice = described_class.find_by(name: 'Alice')

      expect(users[%w[Alice alice@example.com]]).to eq(alice)
      expect(users[%w[Bob bob@example.com]]).to eq(bob)
    end

    it 'does not insert any data when all users exist' do
      bob = create(
        :merge_request_diff_commit_user,
        name: 'Bob',
        email: 'bob@example.com'
      )

      users = described_class.bulk_find_or_create([%w[Bob bob@example.com]])

      expect(described_class).not_to receive(:insert_all)
      expect(users[%w[Bob bob@example.com]]).to eq(bob)
    end

    it 'handles concurrently inserted rows' do
      bob = create(
        :merge_request_diff_commit_user,
        name: 'Bob',
        email: 'bob@example.com'
      )

      input = [%w[Bob bob@example.com]]

      expect(described_class)
        .to receive(:bulk_find)
        .twice
        .with(input)
        .and_return([], [bob])

      users = described_class.bulk_find_or_create(input)

      expect(users[%w[Bob bob@example.com]]).to eq(bob)
    end
  end
end

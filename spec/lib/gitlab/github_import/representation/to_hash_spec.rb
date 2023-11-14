# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ToHash, feature_category: :importers do
  describe '#to_hash' do
    let(:user) { double(:user, attributes: { login: 'alice' }) }

    let(:issue) do
      double(
        :issue,
        attributes: { user: user, assignees: [user], number: 42, created_at: 5.days.ago, status: :valid }
      )
    end

    let(:issue_hash) { issue.to_hash }

    before do
      user.extend(described_class)
      issue.extend(described_class)
    end

    it 'converts an object to a Hash' do
      expect(issue_hash).to be_an_instance_of(Hash)
    end

    it 'converts nested objects to Hashes' do
      expect(issue_hash[:user]).to eq({ login: 'alice' })
    end

    it 'converts Array values to Hashes' do
      expect(issue_hash[:assignees]).to eq([{ login: 'alice' }])
    end

    it 'keeps values as-is if they do not respond to #to_hash' do
      expect(issue_hash[:number]).to eq(42)
    end

    it 'converts Date value to String' do
      expect(issue_hash[:created_at]).to be_an_instance_of(String)
    end

    it 'converts Symbol value to String' do
      expect(issue_hash[:status]).to be_an_instance_of(String)
    end
  end
end

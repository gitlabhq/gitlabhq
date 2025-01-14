# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::PullRequestReview, feature_category: :importers do
  let(:submitted_at) { Time.new(2017, 1, 1, 12, 00).utc }

  shared_examples 'a PullRequest review' do
    it 'returns an instance of PullRequest' do
      expect(review).to be_an_instance_of(described_class)
      expect(review.author).to be_an_instance_of(Gitlab::GithubImport::Representation::User)
      expect(review.author.id).to eq(4)
      expect(review.author.login).to eq('alice')
      expect(review.note).to eq('note')
      expect(review.review_type).to eq('APPROVED')
      expect(review.submitted_at).to eq(submitted_at)
      expect(review.review_id).to eq(999)
      expect(review.merge_request_id).to eq(42)
    end
  end

  describe '.from_api_response' do
    let(:response) do
      {
        id: 999,
        merge_request_id: 42,
        body: 'note',
        state: 'APPROVED',
        user: { id: 4, login: 'alice' },
        submitted_at: submitted_at
      }
    end

    it_behaves_like 'a PullRequest review' do
      let(:review) { described_class.from_api_response(response) }
    end

    it 'does not set the user if the response did not include a user' do
      response[:user] = nil

      review = described_class.from_api_response(response)

      expect(review.author).to be_nil
    end
  end

  describe '.from_json_hash' do
    let(:hash) do
      {
        'review_id' => 999,
        'merge_request_id' => 42,
        'note' => 'note',
        'review_type' => 'APPROVED',
        'author' => { 'id' => 4, 'login' => 'alice' },
        'submitted_at' => submitted_at.to_s
      }
    end

    it_behaves_like 'a PullRequest review' do
      let(:review) { described_class.from_json_hash(hash) }
    end

    it 'does not set the user if the response did not include a user' do
      review = described_class.from_json_hash(hash.except('author'))

      expect(review.author).to be_nil
    end

    it 'does not fail when submitted_at is blank' do
      review = described_class.from_json_hash(hash.except('submitted_at'))

      expect(review.submitted_at).to be_nil
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      github_identifiers = {
        review_id: 999,
        merge_request_iid: 1
      }
      other_attributes = { something_else: '_something_else_' }
      review = described_class.new(github_identifiers.merge(other_attributes))

      expect(review.github_identifiers).to eq(github_identifiers)
    end
  end
end

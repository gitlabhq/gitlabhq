# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::PullRequestReview do
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
      expect(review.github_id).to eq(999)
      expect(review.merge_request_id).to eq(42)
    end
  end

  describe '.from_api_response' do
    let(:response) do
      double(
        :response,
        id: 999,
        merge_request_id: 42,
        body: 'note',
        state: 'APPROVED',
        user: double(:user, id: 4, login: 'alice'),
        submitted_at: submitted_at
      )
    end

    it_behaves_like 'a PullRequest review' do
      let(:review) { described_class.from_api_response(response) }
    end

    it 'does not set the user if the response did not include a user' do
      allow(response)
        .to receive(:user)
        .and_return(nil)

      review = described_class.from_api_response(response)

      expect(review.author).to be_nil
    end
  end

  describe '.from_json_hash' do
    let(:hash) do
      {
        'github_id' => 999,
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
end

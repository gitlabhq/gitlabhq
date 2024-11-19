# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::PullRequests::ReviewRequests, feature_category: :importers do
  shared_examples 'Review requests' do
    it 'returns an instance of Review Request' do
      expect(review_requests).to be_an_instance_of(described_class)
    end

    context 'for returned Review Requests' do
      it 'includes merge request id' do
        expect(review_requests.merge_request_id).to eq(merge_request_id)
      end

      it 'includes reviewers' do
        expect(review_requests.users.size).to eq 2

        user = review_requests.users[0]
        expect(user).to be_an_instance_of(Gitlab::GithubImport::Representation::User)
        expect(user.id).to eq(4)
        expect(user.login).to eq('alice')
      end
    end
  end

  let(:merge_request_id) { 6501124486 }
  let(:response) do
    {
      'merge_request_id' => merge_request_id,
      'users' => [
        { 'id' => 4, 'login' => 'alice' },
        { 'id' => 5, 'login' => 'bob' }
      ]
    }
  end

  describe '.from_api_response' do
    it_behaves_like 'Review requests' do
      let(:review_requests) { described_class.from_api_response(response) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'Review requests' do
      let(:review_requests) { described_class.from_json_hash(response) }
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      review_requests = {
        merge_request_iid: 2,
        merge_request_id: merge_request_id,
        users: [
          { id: 4, login: 'alice' },
          { id: 5, login: 'bob' }
        ]
      }

      github_identifiers = {
        merge_request_iid: 2,
        requested_reviewers: %w[alice bob]
      }

      other_attributes = { merge_request_id: 123, something_else: '_something_else_' }
      review_requests = described_class.new(review_requests.merge(other_attributes))

      expect(review_requests.github_identifiers).to eq(github_identifiers)
    end
  end
end

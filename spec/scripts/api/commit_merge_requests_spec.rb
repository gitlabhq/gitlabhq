# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/api/commit_merge_requests'

RSpec.describe CommitMergeRequests, feature_category: :tooling do
  describe '#execute' do
    let(:options) do
      {
        sha: 'asdf1234',
        api_token: 'token',
        project: 12345,
        endpoint: 'https://example.gitlab.com'
      }
    end

    subject { described_class.new(options).execute }

    it 'requests commit_merge_requests from the gitlab client' do
      expected_result = ['results']
      client = double('Gitlab::Client', commit_merge_requests: expected_result) # rubocop:disable RSpec/VerifiedDoubles

      expect(Gitlab).to receive(:client)
        .with(endpoint: options[:endpoint], private_token: options[:api_token])
        .and_return(client)

      expect(subject).to eq(expected_result)
    end
  end
end

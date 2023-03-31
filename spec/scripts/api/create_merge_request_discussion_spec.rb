# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/api/create_merge_request_discussion'

RSpec.describe CreateMergeRequestDiscussion, feature_category: :tooling do
  describe '#execute' do
    let(:project_id) { 12345 }
    let(:iid) { 1 }
    let(:content) { 'test123' }

    let(:options) do
      {
        api_token: 'token',
        endpoint: 'https://example.gitlab.com',
        project: project_id,
        merge_request: {
          'iid' => iid
        }
      }
    end

    subject { described_class.new(options).execute(content) }

    it 'requests commit_merge_requests from the gitlab client' do
      expected_result = true
      client = double('Gitlab::Client') # rubocop:disable RSpec/VerifiedDoubles

      expect(Gitlab).to receive(:client)
        .with(endpoint: options[:endpoint], private_token: options[:api_token])
        .and_return(client)

      expect(client).to receive(:create_merge_request_discussion).with(
        project_id, iid, body: content
      ).and_return(expected_result)

      expect(subject).to eq(expected_result)
    end
  end
end

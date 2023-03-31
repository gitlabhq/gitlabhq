# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/api/get_package_and_test_job'

RSpec.describe GetPackageAndTestJob, feature_category: :tooling do
  describe '#execute' do
    let(:project) { 12345 }
    let(:pipeline_id) { 1 }

    let(:options) do
      {
        api_token: 'token',
        endpoint: 'https://example.gitlab.com',
        project: project,
        pipeline_id: pipeline_id
      }
    end

    subject { described_class.new(options).execute }

    it 'requests commit_merge_requests from the gitlab client' do
      client_result = [
        { 'name' => 'foo' },
        { 'name' => 'e2e:package-and-test-ee' },
        { 'name' => 'bar' }
      ]
      client = double('Gitlab::Client') # rubocop:disable RSpec/VerifiedDoubles
      client_response = double('Gitlab::ClientResponse') # rubocop:disable RSpec/VerifiedDoubles

      expect(Gitlab).to receive(:client)
        .with(endpoint: options[:endpoint], private_token: options[:api_token])
        .and_return(client)

      expect(client).to receive(:pipeline_bridges).with(
        project, pipeline_id, scope: 'failed', per_page: 100
      ).and_return(client_response)

      expect(client_response).to receive(:auto_paginate)
        .and_yield(client_result[0])
        .and_yield(client_result[1])
        .and_yield(client_result[2])

      expect(subject).to eq(client_result[1])
    end
  end
end

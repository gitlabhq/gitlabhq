# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/webmock'
require_relative '../../../scripts/pipeline/set_pipeline_name'

RSpec.describe SetPipelineName, feature_category: :tooling do
  include StubENV

  let(:instance)               { described_class.new(api_endpoint: 'gitlab.test', gitlab_access_token: 'xxx') }
  let(:original_pipeline_name) { "Ruby 3.2 MR" }
  let(:project_id)             { '123' }
  let(:merge_request_iid)      { '1234' }
  let(:pipeline_id)            { '5678' }
  let(:merge_request_labels)   { ['Engineering Productivity', 'type::feature', 'pipeline::tier-3'] }

  let(:put_url) { "https://gitlab.test/api/v4/projects/#{project_id}/pipelines/#{pipeline_id}/metadata" }

  let(:jobs)    { ['docs-lint markdown'] }
  let(:bridges) { ['rspec:predictive:trigger'] }

  # We need to take some precautions when using the `gitlab` gem in this project.
  #
  # See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
  #
  # rubocop:disable RSpec/VerifiedDoubles -- See the disclaimer above
  let(:api_client) { double('Gitlab::Client') }

  before do
    stub_env(
      'CI_API_V4_URL' => 'https://gitlab.test/api/v4',
      'CI_MERGE_REQUEST_IID' => merge_request_iid,
      'CI_PIPELINE_ID' => pipeline_id,
      'CI_PIPELINE_NAME' => original_pipeline_name,
      'CI_PROJECT_ID' => project_id,
      'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => 'xxx',
      'CI_MERGE_REQUEST_LABELS' => merge_request_labels.empty? ? nil : merge_request_labels.join(',')
    )

    stub_request(:put, put_url).to_return(status: 200, body: 'OK')

    # Gitlab client stubbing
    stub_const('Gitlab::Error::Error', Class.new)
    allow(instance).to receive(:api_client).and_return(api_client)
    allow(api_client).to yield_jobs(:pipeline_jobs, jobs)
    allow(api_client).to yield_jobs(:pipeline_bridges, bridges)

    # Ensure we don't output to stdout while running tests
    allow(instance).to receive(:puts)
  end

  def yield_jobs(api_method, jobs)
    messages = receive_message_chain(api_method, :auto_paginate)

    jobs.inject(messages) do |stub, job_name|
      stub.and_yield(double(name: job_name))
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#execute' do
    context 'when the pipeline is not from a merge request' do
      let(:merge_request_iid)    { nil }
      let(:merge_request_labels) { [] }

      it 'does not add a pipeline tier' do
        instance.execute

        expect(WebMock).to have_requested(:put, put_url).with { |req| req.body.include?('tier:N/A') }
      end

      it 'changes the pipeline types' do
        instance.execute

        # Why not a block with do..end? https://github.com/bblimke/webmock/issues/174#issuecomment-34908908
        expect(WebMock).to have_requested(:put, put_url).with { |req|
          req.body.include?('types:rspec-predictive,docs')
        }
      end
    end

    context 'when the pipeline is from a merge request' do
      it 'adds a pipeline tier' do
        instance.execute

        expect(WebMock).to have_requested(:put, put_url).with { |req| req.body.include?('tier:3') }
      end

      it 'adds the pipeline types' do
        instance.execute

        # Why not a block with do..end? https://github.com/bblimke/webmock/issues/174#issuecomment-34908908
        expect(WebMock).to have_requested(:put, put_url).with { |req|
          req.body.include?('types:rspec-predictive,docs')
        }
      end

      context 'when the merge request does not have a pipeline tier label' do
        let(:merge_request_labels) { ['Engineering Productivity', 'type::feature'] }

        it 'adds the N/A pipeline tier' do
          instance.execute

          expect(WebMock).to have_requested(:put, put_url).with { |req| req.body.include?('tier:N/A') }
        end
      end

      context 'when the merge request has the `pipeline::expedited` label' do
        let(:merge_request_labels) { ['pipeline::expedited'] }

        it 'adds the expedited pipeline type' do
          instance.execute

          expect(WebMock).to have_requested(:put, put_url).with { |req| req.body.include?('types:expedited') }
        end
      end

      context 'when the merge request has the `pipeline:foo-bar` and `pipeline:bar-baz` label' do
        let(:merge_request_labels) { ['pipeline:foo-bar', 'pipeline:bar-baz'] }

        it 'adds the expedited pipeline type' do
          instance.execute

          expect(WebMock).to have_requested(:put, put_url).with { |req| req.body.include?('opts:foo-bar,bar-baz') }
        end
      end
    end
  end

  context 'when we could not update the pipeline name' do
    before do
      stub_request(:put, put_url).to_return(status: 502, body: 'NOT OK')
    end

    it 'displays an error message' do
      allow(instance).to receive(:puts).and_call_original

      expect { instance.execute }.to output(/Failed to set pipeline name: NOT OK/).to_stdout
    end

    it 'returns an error code of 3' do
      expect(instance.execute).to eq(3)
    end
  end
end

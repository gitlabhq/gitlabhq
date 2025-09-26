# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/release_environment/update_merge_requests_label'

RSpec.describe UpdateMergeRequestsLabel, feature_category: :delivery do
  let(:api_endpoint) { 'https://example.gitlab.com/api/v4' }
  let(:project_id) { '12345' }
  let(:deployment_id) { '12345' }
  let(:api_token) { 'test-token' }
  let(:gitlab_client) { double('Gitlab::Client') } # rubocop:disable RSpec/VerifiedDoubles -- mock only
  let(:logger) { double('Logger') } # rubocop:disable RSpec/VerifiedDoubles -- mock only

  subject(:updater) { described_class.new }

  before do
    stub_const('ENV', {
      'CI_API_V4_URL' => api_endpoint,
      'COM_RELEASE_TOOLS_BOT' => api_token,
      'DEPLOYMENT_ID' => deployment_id
    })

    stub_const('UpdateMergeRequestsLabel::PROJECT_ID', project_id)

    allow(Gitlab).to receive(:client).with(
      endpoint: api_endpoint,
      private_token: api_token
    ).and_return(gitlab_client)

    allow(Logger).to receive(:new).with($stdout).and_return(logger)
    allow(logger).to receive(:error)
  end

  describe '#initialize' do
    it 'creates a GitLab client with correct parameters' do
      expect(Gitlab).to receive(:client).with(
        endpoint: api_endpoint,
        private_token: api_token
      )

      updater
    end

    it 'creates a logger' do
      expect(Logger).to receive(:new).with($stdout)
      updater
    end
  end

  describe '#execute' do
    context 'when deployment_mrs is empty' do
      before do
        allow(updater).to receive(:deployment_mrs).and_return([])
      end

      it 'returns early without processing' do
        expect(gitlab_client).not_to receive(:update_merge_request)
        updater.execute
      end
    end

    context 'when deployment_mrs contains merge requests' do
      let(:mr1) do
        double('MR1', # rubocop:disable RSpec/VerifiedDoubles -- stub only
          project_id: 123,
          iid: 456,
          labels: ['bug', 'workflow::in-progress', 'frontend'],
          web_url: 'https://example.gitlab.com/mr'
        )
      end

      before do
        allow(updater).to receive(:deployment_mrs).and_return([mr1])
        allow(logger)
          .to receive(:info)
                .with(
                  "Adding label 'workflow::release-environment' to merge request.",
                  merge_request_url: mr1.web_url
                )
        allow(logger).to receive(:info).with(
          "Found merge requests for deployment.",
          deployment_id: deployment_id,
          merge_request_count: 1
        )
      end

      it 'updates merge request with workflow::release-environment label' do
        expect(gitlab_client).to receive(:update_merge_request).with(
          123, 456, labels: 'workflow::release-environment,bug,frontend'
        )

        updater.execute
      end

      context 'when API call fails' do
        before do
          allow(gitlab_client).to receive(:update_merge_request)
                                    .with(123, 456, anything)
                                    .and_raise(StandardError.new('API Error'))
        end

        it 'logs error and continues processing other MRs' do
          expect(logger).to receive(:error).with(
            "Could not add label 'workflow::release-environment' to " \
              "merge request.",
            merge_request_url: mr1.web_url,
            error_message: "API Error"
          )

          updater.execute
        end
      end
    end
  end

  describe '#deployment_mrs' do
    it 'calls the correct API endpoint' do
      expect(gitlab_client).to receive(:get).with(
        "/projects/#{project_id}/deployments/#{deployment_id}/merge_requests"
      )

      updater.send(:deployment_mrs)
    end

    context 'when API call fails' do
      before do
        allow(gitlab_client).to receive(:get)
                                  .and_raise(StandardError.new('Network Error'))
      end

      it 'logs error and returns empty array' do
        expect(logger).to receive(:error).with(
          "Could not retrieve merge requests for deployment.",
          deployment_id: deployment_id,
          error_message: "Network Error"
        )

        result = updater.send(:deployment_mrs)
        expect(result).to be_empty
      end
    end
  end
end

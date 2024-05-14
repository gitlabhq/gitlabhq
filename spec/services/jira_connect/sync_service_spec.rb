# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncService, feature_category: :integrations do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:merge_request_reviewer) { create(:merge_request_reviewer, merge_request: merge_request) }

    let(:client) { Atlassian::JiraConnect::Client }
    let(:info) { { a: 'Some', b: 'Info', merge_requests: [merge_request] } }

    subject do
      described_class.new(project).execute(**info)
    end

    before do
      create(:jira_connect_subscription, namespace: project.namespace)
    end

    def store_info(return_values = [{ status: 'success' }])
      receive(:send_info).with(project: project, **info).and_return(return_values)
    end

    def expect_log(type, message)
      expect(Gitlab::IntegrationsLogger)
        .to receive(type).with(
          {
            message: 'response from jira dev_info api',
            integration: 'JiraConnect',
            project_id: project.id,
            project_path: project.full_path,
            jira_response: message&.to_json
          }
        )
    end

    it 'calls Atlassian::JiraConnect::Client#store_dev_info and logs the response' do
      expect_next(client).to store_info

      expect_log(:info, { status: 'success' })

      subject
    end

    it 'does not execute any queries for preloaded reviewers' do
      expect_next(client).to store_info

      expect_log(:info, { status: 'success' })

      amount = ActiveRecord::QueryRecorder
        .new { info[:merge_requests].flat_map(&:merge_request_reviewers).map(&:reviewer) }
        .count

      expect(amount).to be_zero

      subject
    end

    context 'when a request returns errors' do
      it 'logs each response as an error' do
        expect_next(client).to store_info(
          [
            { 'errorMessages' => ['some error message'] },
            { 'errorMessage' => 'a single error message' },
            { 'errorMessages' => [] },
            { 'errorMessage' => '' }
          ])

        expect_log(:error, { 'errorMessages' => ['some error message'] })
        expect_log(:error, { 'errorMessage' => 'a single error message' })

        subject
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncService do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }

    let(:client) { Atlassian::JiraConnect::Client }
    let(:info) { { a: 'Some', b: 'Info' } }

    subject do
      described_class.new(project).execute(**info)
    end

    before do
      create(:jira_connect_subscription, namespace: project.namespace)
    end

    def store_info(return_values = [{ 'status': 'success' }])
      receive(:send_info).with(project: project, **info).and_return(return_values)
    end

    def expect_log(type, message)
      expect(Gitlab::ProjectServiceLogger)
        .to receive(type).with(
          message: 'response from jira dev_info api',
          integration: 'JiraConnect',
          project_id: project.id,
          project_path: project.full_path,
          jira_response: message&.to_json
        )
    end

    it 'calls Atlassian::JiraConnect::Client#store_dev_info and logs the response' do
      expect_next(client).to store_info

      expect_log(:info, { 'status': 'success' })

      subject
    end

    context 'when a request returns an error' do
      it 'logs the response as an error' do
        expect_next(client).to store_info([
          { 'errorMessages' => ['some error message'] },
          { 'errorMessages' => ['x'] }
        ])

        expect_log(:error, { 'errorMessages' => ['some error message'] })
        expect_log(:error, { 'errorMessages' => ['x'] })

        subject
      end
    end
  end
end

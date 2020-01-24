# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::IssueLatestEventService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:result) { subject.execute }

  let(:error_tracking_setting) do
    create(:project_error_tracking_setting, api_url: sentry_url, token: token, project: project)
  end

  subject { described_class.new(project, user) }

  before do
    expect(project).to receive(:error_tracking_setting).at_least(:once).and_return(error_tracking_setting)

    project.add_reporter(user)
  end

  describe '#execute' do
    context 'with authorized user' do
      context 'when issue_latest_event returns an error event' do
        let(:error_event) { build(:error_tracking_error_event) }

        before do
          expect(error_tracking_setting)
            .to receive(:issue_latest_event).and_return(latest_event: error_event)
        end

        it 'returns the error event' do
          expect(result).to eq(status: :success, latest_event: error_event)
        end
      end

      include_examples 'error tracking service data not ready', :issue_latest_event
      include_examples 'error tracking service sentry error handling', :issue_latest_event
      include_examples 'error tracking service http status handling', :issue_latest_event
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::IssueDetailsService do
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
      context 'when issue_details returns a detailed error' do
        let(:detailed_error) { build(:detailed_error_tracking_error) }

        before do
          expect(error_tracking_setting)
            .to receive(:issue_details).and_return(issue: detailed_error)
        end

        it 'returns the detailed error' do
          expect(result).to eq(status: :success, issue: detailed_error)
        end
      end

      include_examples 'error tracking service data not ready', :issue_details
      include_examples 'error tracking service sentry error handling', :issue_details
      include_examples 'error tracking service http status handling', :issue_details
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end

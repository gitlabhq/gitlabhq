# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueDetailsService do
  include_context 'sentry error tracking context'

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when issue_details returns a detailed error' do
        let(:detailed_error) { build(:detailed_error_tracking_error) }
        let(:params) { { issue_id: detailed_error.id } }

        before do
          expect(error_tracking_setting)
            .to receive(:issue_details).and_return(issue: detailed_error)
        end

        it 'returns the detailed error' do
          expect(result).to eq(status: :success, issue: detailed_error)
        end

        it 'returns the gitlab_issue when the error has a sentry_issue' do
          gitlab_issue = create(:issue, project: project)
          create(:sentry_issue, issue: gitlab_issue, sentry_issue_identifier: detailed_error.id)

          expect(result[:issue].gitlab_issue).to include(
            "http", "/#{project.full_path}/-/issues/#{gitlab_issue.iid}"
          )
        end

        it 'returns the gitlab_issue path from sentry when the error has no sentry_issue' do
          expect(result[:issue].gitlab_issue).to eq(detailed_error.gitlab_issue)
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

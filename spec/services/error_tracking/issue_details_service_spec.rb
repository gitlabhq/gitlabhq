# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueDetailsService, feature_category: :error_tracking do
  include_context 'sentry error tracking context'

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when issue_details returns a detailed error' do
        let(:detailed_error) { build(:error_tracking_sentry_detailed_error) }
        let(:params) { { issue_id: detailed_error.id } }

        before do
          allow(error_tracking_setting)
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

      context 'with integrated error tracking' do
        let_it_be(:error) { create(:error_tracking_error, project: project) }

        let(:params) { { issue_id: error.id } }

        before do
          error_tracking_setting.update!(integrated: true)
        end

        it 'returns the error in detailed format' do
          expect(result[:status]).to eq(:success)
          expect(result[:issue].to_json).to eq(error.to_sentry_detailed_error.to_json)
        end

        context 'when error does not exist' do
          let(:params) { { issue_id: non_existing_record_id } }

          it 'returns the error in detailed format' do
            expect(result).to match(
              status: :error,
              message: /Couldn't find ErrorTracking::Error/,
              http_status: :bad_request
            )
          end
        end
      end
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end

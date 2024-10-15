# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueDetailsService, feature_category: :observability do
  include_context 'sentry error tracking context'

  subject(:service) { described_class.new(project, user, params) }

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
        let(:error_repository) { instance_double(Gitlab::ErrorTracking::ErrorRepository) }
        let(:params) { { issue_id: issue_id } }

        before do
          error_tracking_setting.update!(integrated: true)

          allow(service).to receive(:error_repository).and_return(error_repository)
        end

        context 'when error is found' do
          let(:error) { build_stubbed(:error_tracking_open_api_error, project_id: project.id) }
          let(:issue_id) { error.fingerprint }

          before do
            allow(error_repository).to receive(:find_error).with(issue_id).and_return(error)
          end

          it 'returns the error in detailed format' do
            expect(result[:status]).to eq(:success)
            expect(result[:issue]).to eq(error)
          end
        end

        context 'when error does not exist' do
          let(:issue_id) { non_existing_record_id }

          before do
            allow(error_repository).to receive(:find_error).with(issue_id)
              .and_raise(Gitlab::ErrorTracking::ErrorRepository::DatabaseError.new('Error not found'))
          end

          it 'returns the error in detailed format' do
            expect(result).to match(
              status: :error,
              message: /Error not found/,
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

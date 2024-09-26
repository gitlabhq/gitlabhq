# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueUpdateService, feature_category: :observability do
  include_context 'sentry error tracking context'

  let(:arguments) { { issue_id: non_existing_record_id, status: 'resolved' } }

  subject(:update_service) { described_class.new(project, user, arguments) }

  shared_examples 'does not perform close issue flow' do
    it 'does not call the close issue service' do
      update_service.execute

      expect(issue_close_service).not_to have_received(:execute)
    end

    it 'does not create system note' do
      expect(SystemNoteService).not_to receive(:close_after_error_tracking_resolve)
      update_service.execute
    end
  end

  describe '#execute' do
    context 'with authorized user' do
      context 'when update_issue returns success' do
        let(:update_issue_response) { { updated: true } }

        before do
          allow(error_tracking_setting).to receive(:update_issue).and_return(update_issue_response)
        end

        it 'returns the response' do
          expect(update_service.execute).to eq(update_issue_response.merge(status: :success, closed_issue_iid: nil))
        end

        it 'updates any related issue' do
          expect(update_service).to receive(:update_related_issue)

          update_service.execute
        end

        it 'clears the reactive cache' do
          expect(error_tracking_setting).to receive(:expire_issues_cache)

          result
        end

        context 'with related issue and resolving' do
          let(:issue) { create(:issue, project: project) }
          let(:sentry_issue) { create(:sentry_issue, issue: issue) }
          let(:arguments) { { issue_id: sentry_issue.sentry_issue_identifier, status: 'resolved' } }
          let(:issue_close_service) { instance_double('Issues::CloseService') }

          before do
            allow_next_instance_of(SentryIssueFinder) do |finder|
              allow(finder).to receive(:execute).and_return(sentry_issue)
            end

            allow(Issues::CloseService)
              .to receive(:new)
              .and_return(issue_close_service)

            allow(issue_close_service)
              .to receive(:execute)
              .and_return(issue)
          end

          it 'closes the issue' do
            update_service.execute

            expect(issue_close_service)
              .to have_received(:execute)
              .with(issue, system_note: false)
          end

          context 'when issue gets closed' do
            let(:closed_issue) { create(:issue, :closed, project: project) }

            before do
              allow(issue_close_service)
                .to receive(:execute)
                .with(issue, system_note: false)
                .and_return(closed_issue)
            end

            it 'creates a system note' do
              expect(SystemNoteService).to receive(:close_after_error_tracking_resolve)

              update_service.execute
            end

            it 'returns a response with closed issue' do
              expect(update_service.execute).to eq(status: :success, updated: true, closed_issue_iid: closed_issue.iid)
            end
          end

          context 'when issue is already closed' do
            let(:issue) { create(:issue, :closed, project: project) }

            include_examples 'does not perform close issue flow'
          end

          context 'when status is not resolving' do
            let(:arguments) { { issue_id: sentry_issue.sentry_issue_identifier, status: 'ignored' } }

            include_examples 'does not perform close issue flow'
          end
        end
      end

      include_examples 'error tracking service sentry error handling', :update_issue

      context 'with integrated error tracking' do
        let(:error_repository) { instance_double(Gitlab::ErrorTracking::ErrorRepository) }
        let(:error) { build_stubbed(:error_tracking_open_api_error, project_id: project.id) }
        let(:issue_id) { error.fingerprint }
        let(:arguments) { { issue_id: issue_id, status: 'resolved' } }

        before do
          error_tracking_setting.update!(integrated: true)

          allow(update_service).to receive(:error_repository).and_return(error_repository)
          allow(error_repository).to receive(:update_error)
            .with(issue_id, status: 'resolved').and_return(updated)
        end

        context 'when update succeeded' do
          let(:updated) { true }

          it 'returns success with updated true' do
            expect(project.error_tracking_setting).to receive(:expire_issues_cache)

            expect(update_service.execute).to eq(
              status: :success,
              updated: true,
              closed_issue_iid: nil
            )
          end
        end

        context 'when update failed' do
          let(:updated) { false }

          it 'returns success with updated false' do
            expect(project.error_tracking_setting).to receive(:expire_issues_cache)

            expect(update_service.execute).to eq(
              status: :success,
              updated: false,
              closed_issue_iid: nil
            )
          end
        end
      end
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipants::DestroyService, feature_category: :service_desk do
  shared_examples 'a successful service execution' do
    it 'removes participants', :aggregate_failures do
      expect(response).to be_success

      issue.reset
      note = issue.notes.last
      expect(note.system?).to be true
      expect(note.author).to eq(expected_user)

      participants_emails = issue.email_participants_emails_downcase

      expected_emails.each do |email|
        expect(participants_emails).not_to include(email)
        expect(response.message).to include(email)
        expect(note.note).to include(email)
        expect(note.note).to include(expected_text_part)
      end
    end
  end

  shared_examples 'a failed service execution' do
    it 'returns error ServiceResponse with message', :aggregate_failures do
      expect(response).to be_error
      expect(response.message).to eq(error_message)
    end
  end

  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }

    let(:emails) { nil }
    let(:options) { {} }
    let(:service) { described_class.new(target: issue, current_user: user, emails: emails, options: options) }
    let(:expected_emails) { emails }

    let(:error_feature_flag) { "Feature flag issue_email_participants is not enabled for this project." }
    let(:error_underprivileged) { _("You don't have permission to manage email participants.") }
    let(:error_no_participants_removed) do
      _("No email participants were removed. Either none were provided, or they don't exist.")
    end

    let(:expected_user) { user }
    let(:expected_text_part) { 'removed' }

    subject(:response) { service.execute }

    context 'when the user is not a project member' do
      let(:error_message) { error_underprivileged }

      it_behaves_like 'a failed service execution'

      context 'when skip_permission_check option is provided' do
        let(:error_message) { error_no_participants_removed }
        let(:options) { { skip_permission_check: true } }

        it_behaves_like 'a failed service execution'

        context 'when email is a participant of the issue' do
          let(:emails) { ['user@example.com'] }

          before do
            issue.issue_email_participants.create!(email: 'user@example.com')
          end

          it_behaves_like 'a successful service execution'
        end
      end
    end

    context 'when user has reporter role in project' do
      before_all do
        project.add_reporter(user)
      end

      context 'when no emails are provided' do
        let(:error_message) { error_no_participants_removed }

        it_behaves_like 'a failed service execution'
      end

      context 'when one email is provided' do
        let(:emails) { ['user@example.com'] }
        let(:error_message) { error_no_participants_removed }

        it_behaves_like 'a failed service execution'

        context 'when email is a participant of the issue' do
          before do
            issue.issue_email_participants.create!(email: 'user@example.com')
          end

          it_behaves_like 'a successful service execution'

          context 'when context option with :unsubscribe is passed' do
            let(:expected_user) { Users::Internal.support_bot }
            let(:expected_text_part) { 'unsubscribed' }
            let(:options) { { context: :unsubscribe } }

            it_behaves_like 'a successful service execution'
          end

          context 'when email is formatted in a different case' do
            let(:emails) { ['USER@example.com'] }
            let(:expected_emails) { emails.map(&:downcase) }
            let(:error_message) { error_no_participants_removed }

            it_behaves_like 'a successful service execution'
          end
        end
      end

      context 'when multiple emails are provided' do
        let(:emails) { ['user@example.com', 'user2@example.com'] }
        let(:error_message) { error_no_participants_removed }

        it_behaves_like 'a failed service execution'

        context 'when duplicate email provided' do
          let(:emails) { ['user@example.com', 'user@example.com'] }
          let(:expected_emails) { emails[...-1] }

          it_behaves_like 'a failed service execution'
        end

        context 'when one email is a participant of the issue' do
          let(:expected_emails) { emails[...-1] }

          before do
            issue.issue_email_participants.create!(email: emails.first)
          end

          it_behaves_like 'a successful service execution'
        end

        context 'when both emails are a participant of the issue' do
          before do
            emails.each do |email|
              issue.issue_email_participants.create!(email: email)
            end
          end

          it_behaves_like 'a successful service execution'
        end
      end

      context 'when more than the allowed number of emails are provided' do
        let(:emails) { (1..7).map { |i| "user#{i}@example.com" } }
        let(:expected_emails) { emails[...-1] }

        before do
          emails.each do |email|
            issue.issue_email_participants.create!(email: email)
          end
        end

        it_behaves_like 'a successful service execution'
      end
    end
  end
end

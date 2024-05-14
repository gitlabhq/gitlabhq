# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipants::CreateService, feature_category: :service_desk do
  shared_examples 'a successful service execution' do
    it 'creates new participants', :aggregate_failures do
      metric_transaction = instance_double(Gitlab::Metrics::WebTransaction, increment: true, observe: true)
      allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
      expect(metric_transaction).to receive(:add_event).with(:service_desk_new_participant_email)
        .exactly(expected_emails.size).times

      expect(Notify).to receive(:service_desk_new_participant_email).exactly(expected_emails.size).times
        .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))

      response = service.execute
      expect(response).to be_success

      issue.reset
      note = issue.notes.last
      expect(note.system?).to be true
      expect(note.author).to eq(user)
      expect(note.system_note_metadata.action).to eq('issue_email_participants')

      participants_emails = issue.email_participants_emails_downcase

      expected_emails.each do |email|
        expect(participants_emails).to include(email)
        expect(response.message).to include(email)
        expect(note.note).to include(email)
      end
    end
  end

  shared_examples 'a failed service execution' do
    it 'returns error ServiceResponse with message', :aggregate_failures do
      response = service.execute
      expect(response).to be_error
      expect(response.message).to eq(error_message)
    end
  end

  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }

    let(:emails) { nil }
    let(:service) { described_class.new(target: issue, current_user: user, emails: emails) }
    let(:expected_emails) { emails }

    let(:error_feature_flag) { "Feature flag issue_email_participants is not enabled for this project." }
    let(:error_underprivileged) { _("You don't have permission to manage email participants.") }
    let(:error_no_participants_added) do
      _("No email participants were added. Either none were provided, or they already exist.")
    end

    context 'when the user is not a project member' do
      let(:error_message) { error_underprivileged }

      it_behaves_like 'a failed service execution'
    end

    context 'when user has reporter role in project' do
      before_all do
        project.add_reporter(user)
      end

      context 'when no emails are provided' do
        let(:error_message) { error_no_participants_added }

        it_behaves_like 'a failed service execution'
      end

      context 'when one email is provided' do
        let(:emails) { ['user@example.com'] }

        it_behaves_like 'a successful service execution'

        context 'when email is already a participant of the issue' do
          let(:error_message) { error_no_participants_added }

          before do
            issue.issue_email_participants.create!(email: emails.first)
          end

          it_behaves_like 'a failed service execution'

          context 'when email is formatted in a different case' do
            let(:emails) { ['USER@example.com'] }

            it_behaves_like 'a failed service execution'
          end

          context 'when participants limit on issue is reached' do
            before do
              stub_const("#{described_class}::MAX_NUMBER_OF_RECORDS", 1)
            end

            let(:emails) { ['over-max@example.com'] }
            let(:error_message) { error_no_participants_added }

            it_behaves_like 'a failed service execution'

            it 'logs count of emails above limit' do
              expect(Gitlab::AppLogger).to receive(:info).with({ above_limit_count: 1 }).once
              service.execute
            end
          end
        end
      end

      context 'when multiple emails are provided' do
        let(:emails) { ['user@example.com', 'other-user@example.com'] }

        it_behaves_like 'a successful service execution'

        context 'when duplicate email provided' do
          let(:emails) { ['user@example.com', 'user@example.com'] }
          let(:expected_emails) { emails[...-1] }

          it_behaves_like 'a successful service execution'
        end

        context 'when an email is already a participant of the issue' do
          let(:expected_emails) { emails[1...] }

          before do
            issue.issue_email_participants.create!(email: emails.first)
          end

          it_behaves_like 'a successful service execution'
        end

        context 'when only some emails can be added because of participants limit' do
          before do
            stub_const("#{described_class}::MAX_NUMBER_OF_RECORDS", 1)
          end

          let(:expected_emails) { emails[...-1] }

          it_behaves_like 'a successful service execution'

          it 'logs count of emails above limit' do
            expect(Gitlab::AppLogger).to receive(:info).with({ above_limit_count: 1 }).once
            service.execute
          end
        end
      end

      context 'when more than the allowed number of emails are provided' do
        let(:emails) { (1..7).map { |i| "user#{i}@example.com" } }

        let(:expected_emails) { emails[...-1] }

        it_behaves_like 'a successful service execution'
      end
    end

    context 'when feature flag issue_email_participants is disabled' do
      let(:error_message) { error_feature_flag }

      before do
        stub_feature_flags(issue_email_participants: false)
      end

      it_behaves_like 'a failed service execution'
    end
  end
end

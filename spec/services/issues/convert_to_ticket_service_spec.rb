# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ConvertToTicketService, feature_category: :service_desk do
  shared_examples 'a successful service execution' do
    it 'converts issue to Service Desk issue', :aggregate_failures do
      original_author = issue.author

      response = service.execute
      expect(response).to be_success
      expect(response.message).to eq(success_message)

      issue.reset

      expect(issue).to have_attributes(
        confidential: expected_confidentiality,
        author: support_bot,
        service_desk_reply_to: 'user@example.com'
      )

      external_participant = issue.issue_email_participants.last
      expect(external_participant.email).to eq(email)

      note = issue.notes.last
      expect(note.author).to eq(support_bot)
      expect(note.note).to include(email)
      expect(note.note).to include(original_author.to_reference)
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
    let_it_be(:support_bot) { Users::Internal.support_bot }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }

    let(:email) { nil }
    let(:service) { described_class.new(target: issue, current_user: user, email: email) }
    let(:expected_confidentiality) { true }

    let(:error_underprivileged) { _("You don't have permission to manage this issue.") }
    let(:error_already_ticket) { s_("ServiceDesk|Cannot convert to ticket because it is already a ticket.") }
    let(:error_invalid_email) do
      s_("ServiceDesk|Cannot convert issue to ticket because no email was provided or the format was invalid.")
    end

    let(:success_message) { s_('ServiceDesk|Converted issue to Service Desk ticket.') }

    context 'when the user is not a project member' do
      let(:error_message) { error_underprivileged }

      it_behaves_like 'a failed service execution'
    end

    context 'when user has the reporter role in project' do
      before_all do
        project.add_reporter(user)
      end

      context 'without email' do
        let(:error_message) { error_invalid_email }

        it_behaves_like 'a failed service execution'
      end

      context 'with invalid email' do
        let(:email) { 'not-a-valid-email' }
        let(:error_message) { error_invalid_email }

        it_behaves_like 'a failed service execution'
      end

      context 'with valid email' do
        let(:email) { 'user@example.com' }

        it_behaves_like 'a successful service execution'

        context 'when issue already is confidential' do
          before do
            issue.update!(confidential: true)
          end

          it_behaves_like 'a successful service execution'
        end

        context 'with service desk setting' do
          let_it_be_with_reload(:service_desk_setting) { create(:service_desk_setting, project: project) }

          it_behaves_like 'a successful service execution'

          context 'when tickets should not be confidential by default' do
            let(:expected_confidentiality) { false }

            before do
              service_desk_setting.update!(tickets_confidential_by_default: false)
            end

            it_behaves_like 'a successful service execution'

            context 'when project is public' do
              # Tickets are always confidential by default in public projects
              let(:expected_confidentiality) { true }

              before do
                project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
              end

              it_behaves_like 'a successful service execution'
            end

            context 'when issue already is confidential' do
              # Do not change the confidentiality of an already confidential issue
              let(:expected_confidentiality) { true }

              before do
                issue.update!(confidential: true)
              end

              it_behaves_like 'a successful service execution'
            end
          end
        end

        context 'when issue is Service Desk issue' do
          let(:error_message) { error_already_ticket }

          before do
            issue.update!(
              author: Users::Internal.support_bot,
              service_desk_reply_to: 'user@example.com'
            )
          end

          it_behaves_like 'a failed service execution'
        end
      end
    end
  end
end

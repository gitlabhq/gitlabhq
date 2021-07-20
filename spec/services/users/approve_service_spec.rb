# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ApproveService do
  let_it_be(:current_user) { create(:admin) }

  let(:user) { create(:user, :blocked_pending_approval) }

  subject(:execute) { described_class.new(current_user).execute(user) }

  describe '#execute' do
    context 'failures' do
      context 'when the executor user is not allowed to approve users' do
        let(:current_user) { create(:user) }

        it 'returns error result' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to match(/You are not allowed to approve a user/)
        end
      end

      context 'when the executor user is an admin not in admin mode' do
        it 'returns error result' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to match(/You are not allowed to approve a user/)
        end
      end

      context 'when the executor user is an admin in admin mode', :enable_admin_mode do
        context 'when user is not in pending approval state' do
          let(:user) { create(:user, state: 'active') }

          it 'returns error result' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message])
              .to match(/The user you are trying to approve is not pending approval/)
          end
        end

        context 'when user cannot be activated' do
          let(:user) do
            build(:user, state: 'blocked_pending_approval', email: 'invalid email')
          end

          it 'returns error result' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to match(/Email is invalid/)
          end

          it 'does not change the state of the user' do
            expect { subject }.not_to change { user.state }
          end
        end
      end
    end

    context 'success' do
      context 'when the executor user is an admin in admin mode', :enable_admin_mode do
        it 'activates the user' do
          expect(subject[:status]).to eq(:success)
          expect(user.reload).to be_active
        end

        it 'logs approval in application logs' do
          allow(Gitlab::AppLogger).to receive(:info)

          subject

          expect(Gitlab::AppLogger).to have_received(:info).with(message: "User instance access request approved", user: "#{user.username}", email: "#{user.email}", approved_by: "#{current_user.username}", ip_address: "#{current_user.current_sign_in_ip}")
        end

        it 'emails the user on approval' do
          expect(DeviseMailer).to receive(:user_admin_approval).with(user).and_call_original
          expect { subject }.to have_enqueued_mail(DeviseMailer, :user_admin_approval)
        end

        context 'email confirmation status' do
          context 'user is unconfirmed' do
            let(:user) { create(:user, :blocked_pending_approval, :unconfirmed) }

            it 'sends confirmation instructions' do
              expect { subject }
                .to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            end
          end

          context 'user is confirmed' do
            it 'does not send a confirmation email' do
              expect { subject }
                .not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            end
          end

          context 'audit events' do
            context 'when not licensed' do
              before do
                stub_licensed_features(
                  admin_audit_log: false
                )
              end

              it 'does not log any audit event' do
                expect { subject }.not_to change(AuditEvent, :count)
              end
            end
          end
        end

        context 'pending invitations' do
          let!(:project_member_invite) { create(:project_member, :invited, invite_email: user.email) }
          let!(:group_member_invite) { create(:group_member, :invited, invite_email: user.email) }

          context 'user is unconfirmed' do
            let(:user) { create(:user, :blocked_pending_approval, :unconfirmed) }

            it 'does not accept pending invites of the user' do
              expect(subject[:status]).to eq(:success)

              group_member_invite.reload
              project_member_invite.reload

              expect(group_member_invite).to be_invite
              expect(project_member_invite).to be_invite
            end
          end

          context 'user is confirmed' do
            it 'accepts pending invites of the user' do
              expect(subject[:status]).to eq(:success)

              group_member_invite.reload
              project_member_invite.reload

              expect(group_member_invite).not_to be_invite
              expect(project_member_invite).not_to be_invite
              expect(group_member_invite.user).to eq(user)
              expect(project_member_invite.user).to eq(user)
            end
          end
        end
      end
    end
  end
end

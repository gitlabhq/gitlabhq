# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoveUnacceptedMemberInvitesWorker, feature_category: :system_access do
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'with unaccepted members' do
      before do
        stub_const("#{described_class}::EXPIRATION_THRESHOLD", 1.day)
      end

      it 'removes unaccepted members', :aggregate_failures do
        unaccepted_group_invitee = create(
          :group_member,
          invite_token: 't0ken',
          invite_email: 'group_invitee@example.com',
          user: nil,
          created_at: Time.current - 5.days
        )
        unaccepted_project_invitee = create(
          :project_member,
          invite_token: 't0ken',
          invite_email: 'project_invitee@example.com',
          user: nil,
          created_at: Time.current - 5.days
        )

        expect { worker.perform }.to change { Member.count }.by(-2)

        expect(Member.where(id: unaccepted_project_invitee.id)).not_to exist
        expect(Member.where(id: unaccepted_group_invitee.id)).not_to exist
      end
    end

    context 'with invited members still within expiration threshold' do
      it 'leaves invited members', :aggregate_failures do
        group_invitee = create(
          :group_member,
          invite_token: 't0ken',
          invite_email: 'group_invitee@example.com',
          user: nil
        )
        project_invitee = create(
          :project_member,
          invite_token: 't0ken',
          invite_email: 'project_invitee@example.com',
          user: nil
        )

        expect { worker.perform }.not_to change { Member.count }

        expect(Member.where(id: group_invitee.id)).to exist
        expect(Member.where(id: project_invitee.id)).to exist
      end
    end

    context 'with accepted members' do
      before do
        stub_const("#{described_class}::EXPIRATION_THRESHOLD", 1.day)
      end

      it 'leaves accepted members', :aggregate_failures do
        user = create(:user)
        accepted_group_invitee = create(
          :group_member,
          invite_token: 't0ken',
          invite_email: 'group_invitee@example.com',
          user: user,
          created_at: Time.current - 5.days
        )
        accepted_project_invitee = create(
          :project_member,
          invite_token: nil,
          invite_email: 'project_invitee@example.com',
          user: user,
          created_at: Time.current - 5.days
        )

        expect { worker.perform }.not_to change { Member.count }

        expect(Member.where(id: accepted_group_invitee.id)).to exist
        expect(Member.where(id: accepted_project_invitee.id)).to exist
      end
    end

    context 'when cells claims cleanup' do
      before do
        stub_const("#{described_class}::EXPIRATION_THRESHOLD", 1.day)
      end

      let_it_be(:expired_invitee) do
        create(
          :group_member,
          :invited,
          created_at: 5.days.ago
        )
      end

      context 'when invite_email claims are enabled' do
        before do
          allow(Member).to receive(:cells_claims_enabled_for_attribute?)
            .with(:invite_email).and_return(true)
        end

        it 'enqueues BulkClaimsWorker with destroy metadata for the deleted invite' do
          expect(Cells::BulkClaimsWorker).to receive(:perform_async).with(
            'Member',
            'invite_email',
            hash_including(
              'destroy_metadata' => array_including(
                hash_including('bucket_value' => expired_invitee.invite_email, 'primary_key' => expired_invitee.id)
              )
            )
          )

          worker.perform
        end
      end

      context 'when invite_email claims are disabled' do
        before do
          allow(Member).to receive(:cells_claims_enabled_for_attribute?)
            .with(:invite_email).and_return(false)
        end

        it 'does not enqueue BulkClaimsWorker' do
          expect(Cells::BulkClaimsWorker).not_to receive(:perform_async)

          worker.perform
        end

        it 'still deletes the expired invite' do
          expect { worker.perform }.to change { Member.where(id: expired_invitee.id).count }.from(1).to(0)
        end
      end
    end
  end
end

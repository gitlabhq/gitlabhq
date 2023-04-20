# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoveUnacceptedMemberInvitesWorker, feature_category: :system_access do
  let(:worker) { described_class.new }

  describe '#perform' do
    context 'unaccepted members' do
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

    context 'invited members still within expiration threshold' do
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

    context 'accepted members' do
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
  end
end

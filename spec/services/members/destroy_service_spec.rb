require 'spec_helper'

describe Members::DestroyService, services: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:member) { create(:project_member, source: project) }

  context 'when current user cannot destroy the given member' do
    before do
      project.team << [user, :developer]
    end

    it 'does not destroy the member' do
      expect(destroy_member(member, user)).not_to be_destroyed
    end
  end

  context 'when current user can destroy the given member' do
    before do
      project.team << [user, :master]
    end

    it 'destroys the member' do
      expect(destroy_member(member, user)).to be_destroyed
    end

    context 'when the given member is a requester' do
      before do
        member.update_column(:requested_at, Time.now)
      end

      it 'calls Member#after_decline_request' do
        expect_any_instance_of(NotificationService).to receive(:decline_access_request).with(member)

        destroy_member(member, user)
      end

      context 'when current user is the member' do
        it 'does not call Member#after_decline_request' do
          expect_any_instance_of(NotificationService).not_to receive(:decline_access_request).with(member)

          destroy_member(member, member.user)
        end
      end
    end
  end

  def destroy_member(member, user)
    Members::DestroyService.new(member, user).execute
  end
end

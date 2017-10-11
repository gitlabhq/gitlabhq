require 'spec_helper'

describe Members::DestroyService do
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(source, current_user).execute(member) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, current_user).execute(member) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service destroying a member' do
    it 'destroys the member' do
      expect { described_class.new(source, current_user).execute(member) }.to change { source.members.count }.by(-1)
    end
  end

  shared_examples 'a service destroying an access requester' do
    it 'destroys the access requester' do
      expect { described_class.new(source, current_user).execute(access_requester) }.to change { source.requesters.count }.by(-1)
    end

    it 'calls Member#after_decline_request' do
      expect_any_instance_of(NotificationService).to receive(:decline_access_request).with(access_requester)

      described_class.new(source, current_user).execute(access_requester)
    end

    context 'when current user is the member' do
      it 'does not call Member#after_decline_request' do
        expect_any_instance_of(NotificationService).not_to receive(:decline_access_request).with(access_requester)

        described_class.new(source, member_user).execute(access_requester)
      end
    end
  end

  context 'with a member' do
    before do
      project.add_developer(member_user)
      group.add_developer(member_user)
    end
    let(:member) { source.members.find_by(user_id: member_user.id) }

    context 'when current user cannot destroy the given member' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
      end
    end

    context 'when current user can destroy the given member' do
      before do
        project.add_master(current_user)
        group.add_owner(current_user)
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { project }
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { group }
      end
    end
  end

  context 'with an access requester' do
    before do
      project.update_attributes(request_access_enabled: true)
      group.update_attributes(request_access_enabled: true)
      project.request_access(member_user)
      group.request_access(member_user)
    end
    let(:access_requester) { source.requesters.find_by(user_id: member_user.id) }

    context 'when current user cannot destroy the given access requester' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
        let(:member) { access_requester }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
        let(:member) { access_requester }
      end
    end

    context 'when current user can destroy the given access requester' do
      before do
        project.add_master(current_user)
        group.add_owner(current_user)
      end

      it_behaves_like 'a service destroying an access requester' do
        let(:source) { project }
      end

      it_behaves_like 'a service destroying an access requester' do
        let(:source) { group }
      end
    end
  end
end

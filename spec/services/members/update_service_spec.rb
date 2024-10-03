# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::UpdateService, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:member_user1) { create(:user) }
  let_it_be(:member_user2) { create(:user) }
  let_it_be(:member_users) { [member_user1, member_user2] }
  let_it_be(:permission) { :update }
  let_it_be(:access_level) { Gitlab::Access::MAINTAINER }
  let(:members) { source.members_and_requesters.where(user_id: member_users).to_a }
  let(:update_service) { described_class.new(current_user, params) }
  let(:params) { { access_level: access_level, source: source } }
  let(:updated_members) { subject[:members] }

  before do
    member_users.first.tap do |member_user|
      expires_at = 10.days.from_now
      project.add_member(member_user, Gitlab::Access::DEVELOPER, expires_at: expires_at)
      group.add_member(member_user, Gitlab::Access::DEVELOPER, expires_at: expires_at)
    end

    member_users[1..].each do |member_user|
      project.add_developer(member_user)
      group.add_developer(member_user)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { subject }
        .to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'current user cannot update the given members' do
    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let_it_be(:source) { project }
    end

    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let_it_be(:source) { group }
    end
  end

  shared_examples 'returns error status when params are invalid' do
    let_it_be(:params) { { expires_at: 2.days.ago, source: source } }

    specify do
      expect(subject[:status]).to eq(:error)
    end
  end

  shared_examples 'a service updating members' do
    it 'updates the members' do
      new_access_levels = updated_members.map(&:access_level)

      expect(updated_members).not_to be_empty
      expect(updated_members).to all(be_valid)
      expect(new_access_levels).to all(be access_level)
    end

    it 'returns success status' do
      expect(subject.fetch(:status)).to eq(:success)
    end

    it 'invokes after_execute with correct args' do
      members.each do |member|
        expect(update_service).to receive(:after_execute).with(
          action: permission,
          old_access_level: member.human_access_labeled,
          old_expiry: member.expires_at,
          member: member
        )
      end

      subject
    end

    it 'authorization update callback is triggered' do
      expect(members).to all(receive(:refresh_member_authorized_projects).once)

      subject
    end

    it 'does not enqueues todos for deletion' do
      members.each do |member|
        expect(TodosDestroyer::EntityLeaveWorker)
          .not_to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, source.class.name)
      end

      subject
    end

    context 'when members are downgraded to guest' do
      shared_examples 'schedules to delete confidential todos' do
        it do
          members.each do |member|
            expect(TodosDestroyer::EntityLeaveWorker)
              .to receive(:perform_in)
                    .with(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, source.class.name).once
          end

          new_access_levels = updated_members.map(&:access_level)
          expect(updated_members).to all(be_valid)
          expect(new_access_levels).to all(be Gitlab::Access::GUEST)
        end
      end

      context 'with Gitlab::Access::GUEST level as a string' do
        let_it_be(:params) { { access_level: Gitlab::Access::GUEST.to_s, source: source } }

        it_behaves_like 'schedules to delete confidential todos'
      end

      context 'with Gitlab::Access::GUEST level as an integer' do
        let_it_be(:params) { { access_level: Gitlab::Access::GUEST, source: source } }

        it_behaves_like 'schedules to delete confidential todos'
      end
    end

    context 'when access_level is invalid' do
      let_it_be(:params) { { access_level: 'invalid', source: source } }

      it 'raises an error' do
        expect { described_class.new(current_user, params) }
          .to raise_error(ArgumentError, 'invalid value for Integer(): "invalid"')
      end
    end

    context 'when members update results in no change' do
      let(:params) { { access_level: members.first.access_level, source: source } }

      it 'does not invoke update! and post_update' do
        expect(update_service).not_to receive(:save!)
        expect(update_service).not_to receive(:post_update)

        expect(subject[:status]).to eq(:success)
      end

      it 'authorization update callback is not triggered' do
        members.each { |member| expect(member).not_to receive(:refresh_member_authorized_projects) }

        subject
      end
    end
  end

  shared_examples 'updating a project' do
    let_it_be(:group_project) { create(:project, group: create(:group)) }
    let_it_be(:source) { group_project }

    before do
      member_users.each { |member_user| group_project.add_developer(member_user) }
    end

    context 'as a project maintainer' do
      before do
        group_project.add_maintainer(current_user)
      end

      it_behaves_like 'a service updating members'

      context 'when member update results in an error' do
        it_behaves_like 'a service returning an error'
      end

      context 'and updating members to OWNER' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let_it_be(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'and updating themselves to OWNER' do
        let(:members) { source.members_and_requesters.find_by!(user_id: current_user.id) }

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let_it_be(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'and downgrading members from OWNER' do
        before do
          member_users.each { |member_user| group_project.add_owner(member_user) }
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let_it_be(:access_level) { Gitlab::Access::MAINTAINER }
        end
      end
    end

    context 'when current_user is considered an owner in the project via inheritance' do
      before do
        group_project.group.add_owner(current_user)
      end

      context 'and can update members to OWNER' do
        before do
          member_users.each { |member_user| group_project.add_developer(member_user) }
        end

        it_behaves_like 'a service updating members' do
          let_it_be(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'and can downgrade members from OWNER' do
        before do
          member_users.each { |member_user| group_project.add_owner(member_user) }
        end

        it_behaves_like 'a service updating members' do
          let_it_be(:access_level) { Gitlab::Access::MAINTAINER }
        end
      end
    end

    context 'when project members expiration date is updated with expiry_notified_at' do
      let_it_be(:params) { { expires_at: 20.days.from_now, source: source } }

      before do
        group_project.group.add_owner(current_user)
        members.each do |member|
          member.update!(expiry_notified_at: Date.today)
        end
      end

      it "clear expiry_notified_at" do
        subject

        members.each do |member|
          expect(member.reload.expiry_notified_at).to be_nil
        end
      end
    end
  end

  shared_examples 'updating a group' do
    let_it_be(:source) { group }

    before do
      group.add_owner(current_user)
    end

    it_behaves_like 'a service updating members'

    context 'when member update results in an error' do
      it_behaves_like 'a service returning an error'
    end

    context 'when group members expiration date is updated' do
      let_it_be(:params) { { expires_at: 20.days.from_now, source: source } }
      let(:notification_service) { instance_double(NotificationService) }

      before do
        allow(NotificationService).to receive(:new).and_return(notification_service)
      end

      it 'emails the users that their group membership expiry has changed' do
        members.each do |member|
          expect(notification_service).to receive(:updated_member_expiration).with(member)
        end

        subject
      end
    end

    context 'when group members expiration date is updated with expiry_notified_at' do
      let_it_be(:params) { { expires_at: 20.days.from_now, source: source } }

      before do
        members.each do |member|
          member.update!(expiry_notified_at: Date.today)
        end
      end

      it "clear expiry_notified_at" do
        subject

        members.each do |member|
          expect(member.reload.expiry_notified_at).to be_nil
        end
      end
    end
  end

  subject { update_service.execute(members, permission: permission) }

  shared_examples 'a service returning an error' do
    it_behaves_like 'returns error status when params are invalid'

    context 'when a member update results in invalid record' do
      let(:member2) { members.second }

      before do
        allow(member2).to receive(:save!) do
          member2.errors.add(:user_id)
          member2.errors.add(:access_level)
        end.and_raise(ActiveRecord::RecordInvalid)
      end

      it 'returns the error' do
        response = subject

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('User is invalid and Access level is invalid')
      end

      it 'rollbacks back the entire update' do
        old_access_levels = members.pluck(:access_level)

        subject

        expect(members.each(&:reset).pluck(:access_level)).to eq(old_access_levels)
      end
    end
  end

  context 'when passing an invalid source' do
    let_it_be(:source) { Object.new }

    it 'raises a RuntimeError' do
      expect { update_service.execute([]) }.to raise_error(RuntimeError, 'Unknown source type: Object!')
    end
  end

  it_behaves_like 'current user cannot update the given members'
  it_behaves_like 'updating a project'
  it_behaves_like 'updating a group'

  context 'with a single member' do
    let_it_be(:source) { group }
    let(:members) { create(:group_member, group: group) }

    before do
      group.add_owner(current_user)
    end

    it 'returns the correct response' do
      expect(subject[:members]).to contain_exactly(members)
    end
  end

  context 'when current user is an admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:source) { group }

    context 'when all owners are being downgraded' do
      before do
        member_users.each { |member_user| group.add_owner(member_user) }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
    end

    context 'when all blocked owners are being downgraded' do
      before do
        member_users.each do |member_user|
          group.add_owner(member_user)
          member_user.block
        end
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
    end
  end
end

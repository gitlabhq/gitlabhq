# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::UpdateService do
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:permission) { :update }
  let(:member) { source.members_and_requesters.find_by!(user_id: member_user.id) }
  let(:access_level) { Gitlab::Access::MAINTAINER }
  let(:params) do
    { access_level: access_level }
  end

  subject { described_class.new(current_user, params).execute(member, permission: permission) }

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { subject }
        .to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service updating a member' do
    it 'updates the member' do
      expect(TodosDestroyer::EntityLeaveWorker).not_to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, source.class.name)

      updated_member = subject.fetch(:member)

      expect(updated_member).to be_valid
      expect(updated_member.access_level).to eq(access_level)
    end

    it 'returns success status' do
      result = subject.fetch(:status)

      expect(result).to eq(:success)
    end

    context 'when member is downgraded to guest' do
      shared_examples 'schedules to delete confidential todos' do
        it do
          expect(TodosDestroyer::EntityLeaveWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, source.class.name).once

          updated_member = subject.fetch(:member)

          expect(updated_member).to be_valid
          expect(updated_member.access_level).to eq(Gitlab::Access::GUEST)
        end
      end

      context 'with Gitlab::Access::GUEST level as a string' do
        let(:params) { { access_level: Gitlab::Access::GUEST.to_s } }

        it_behaves_like 'schedules to delete confidential todos'
      end

      context 'with Gitlab::Access::GUEST level as an integer' do
        let(:params) { { access_level: Gitlab::Access::GUEST } }

        it_behaves_like 'schedules to delete confidential todos'
      end
    end

    context 'when access_level is invalid' do
      let(:params) { { access_level: 'invalid' } }

      it 'raises an error' do
        expect { described_class.new(current_user, params) }.to raise_error(ArgumentError, 'invalid value for Integer(): "invalid"')
      end
    end

    context 'when member is not valid' do
      let(:params) { { expires_at: 2.days.ago } }

      it 'returns error status' do
        result = subject

        expect(result[:status]).to eq(:error)
      end
    end
  end

  before do
    project.add_developer(member_user)
    group.add_developer(member_user)
  end

  context 'when current user cannot update the given member' do
    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { group }
    end
  end

  context 'when current user can update the given member' do
    before do
      project.add_maintainer(current_user)
      group.add_owner(current_user)
    end

    it_behaves_like 'a service updating a member' do
      let(:source) { project }
    end

    it_behaves_like 'a service updating a member' do
      let(:source) { group }
    end
  end

  context 'in a project' do
    let_it_be(:group_project) { create(:project, group: create(:group)) }

    let(:source) { group_project }

    context 'a project maintainer' do
      before do
        group_project.add_maintainer(current_user)
      end

      context 'cannot update a member to OWNER' do
        before do
          group_project.add_developer(member_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'cannot update themselves to OWNER' do
        let(:member) { source.members_and_requesters.find_by!(user_id: current_user.id) }

        before do
          group_project.add_developer(member_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'cannot downgrade a member from OWNER' do
        before do
          group_project.add_owner(member_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:access_level) { Gitlab::Access::MAINTAINER }
        end
      end
    end

    context 'owners' do
      before do
        # so that `current_user` is considered an `OWNER` in the project via inheritance.
        group_project.group.add_owner(current_user)
      end

      context 'can update a member to OWNER' do
        before do
          group_project.add_developer(member_user)
        end

        it_behaves_like 'a service updating a member' do
          let(:access_level) { Gitlab::Access::OWNER }
        end
      end

      context 'can downgrade a member from OWNER' do
        before do
          group_project.add_owner(member_user)
        end

        it_behaves_like 'a service updating a member' do
          let(:access_level) { Gitlab::Access::MAINTAINER }
        end
      end
    end
  end
end

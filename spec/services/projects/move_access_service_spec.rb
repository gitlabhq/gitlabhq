require 'spec_helper'

describe Projects::MoveAccessService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project_with_access) { create(:project, namespace: user.namespace) }
  let(:master_user) { create(:user) }
  let(:reporter_user) { create(:user) }
  let(:developer_user) { create(:user) }
  let(:master_group) { create(:group) }
  let(:reporter_group) { create(:group) }
  let(:developer_group) { create(:group) }

  before do
    project_with_access.add_master(master_user)
    project_with_access.add_developer(developer_user)
    project_with_access.add_reporter(reporter_user)
    project_with_access.project_group_links.create(group: master_group, group_access: Gitlab::Access::MASTER)
    project_with_access.project_group_links.create(group: developer_group, group_access: Gitlab::Access::DEVELOPER)
    project_with_access.project_group_links.create(group: reporter_group, group_access: Gitlab::Access::REPORTER)
  end

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    shared_examples 'move the accesses' do
      it do
        expect(project_with_access.project_members.count).to eq 4
        expect(project_with_access.project_group_links.count).to eq 3
        expect(project_with_access.authorized_users.count).to eq 4

        subject.execute(project_with_access)

        expect(project_with_access.project_members.count).to eq 0
        expect(project_with_access.project_group_links.count).to eq 0
        expect(project_with_access.authorized_users.count).to eq 1
        expect(target_project.project_members.count).to eq 4
        expect(target_project.project_group_links.count).to eq 3
        expect(target_project.authorized_users.count).to eq 4
      end

      it 'rollbacks if an exception is raised' do
        allow(subject).to receive(:success).and_raise(StandardError)

        expect { subject.execute(project_with_groups) }.to raise_error(StandardError)

        expect(project_with_access.project_members.count).to eq 4
        expect(project_with_access.project_group_links.count).to eq 3
        expect(project_with_access.authorized_users.count).to eq 4
      end
    end

    context 'when both projects are in the same namespace' do
      let(:target_project) { create(:project, namespace: user.namespace) }

      it 'does not refresh project owner authorized projects' do
        allow(project_with_access).to receive(:namespace).and_return(user.namespace)
        expect(project_with_access.namespace).not_to receive(:refresh_project_authorizations)
        expect(target_project.namespace).not_to receive(:refresh_project_authorizations)

        subject.execute(project_with_access)
      end

      it_behaves_like 'move the accesses'
    end

    context 'when projects are in different namespaces' do
      let(:target_project) { create(:project, namespace: group) }

      before do
        group.add_owner(user)
      end

      it 'refreshes both project owner authorized projects' do
        allow(project_with_access).to receive(:namespace).and_return(user.namespace)
        expect(user.namespace).to receive(:refresh_project_authorizations).once
        expect(group).to receive(:refresh_project_authorizations).once

        subject.execute(project_with_access)
      end

      it_behaves_like 'move the accesses'
    end

    context 'when remove_remaining_elements is false' do
      let(:target_project) { create(:project, namespace: user.namespace) }
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining memberships' do
        target_project.add_master(master_user)

        subject.execute(project_with_access, options)

        expect(project_with_access.project_members.count).not_to eq 0
      end

      it 'does not remove remaining group links' do
        target_project.project_group_links.create(group: master_group, group_access: Gitlab::Access::MASTER)

        subject.execute(project_with_access, options)

        expect(project_with_access.project_group_links.count).not_to eq 0
      end

      it 'does not remove remaining authorizations' do
        target_project.add_developer(developer_user)

        subject.execute(project_with_access, options)

        expect(project_with_access.project_authorizations.count).not_to eq 0
      end
    end
  end
end

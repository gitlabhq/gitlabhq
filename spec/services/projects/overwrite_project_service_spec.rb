require 'spec_helper'

describe Projects::OverwriteProjectService do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project_from) { create(:project, namespace: user.namespace) }
  let(:project_to) { create(:project, namespace: user.namespace) }
  let!(:lvl1_forked_project_1) { fork_project(project_from, user) }
  let!(:lvl1_forked_project_2) { fork_project(project_from, user) }
  let!(:lvl2_forked_project_1_1) { fork_project(lvl1_forked_project_1, user) }
  let!(:lvl2_forked_project_1_2) { fork_project(lvl1_forked_project_1, user) }

  subject { described_class.new(project_to, user) }

  before do
    allow(project_to).to receive(:import_data).and_return(double(data: { 'original_path' => project_from.path }))
  end

  describe '#execute' do
    shared_examples 'overwrite actions' do
      it 'moves deploy keys' do
        deploy_keys_count = project_from.deploy_keys_projects.count

        subject.execute(project_from)

        expect(project_to.deploy_keys_projects.count).to eq deploy_keys_count
      end

      it 'moves notification settings' do
        notification_count = project_from.notification_settings.count

        subject.execute(project_from)

        expect(project_to.notification_settings.count).to eq notification_count
      end

      it 'moves users stars' do
        stars_count = project_from.users_star_projects.count

        subject.execute(project_from)
        project_to.reload

        expect(project_to.users_star_projects.count).to eq stars_count
        expect(project_to.star_count).to eq stars_count
      end

      it 'moves project group links' do
        group_links_count = project_from.project_group_links.count

        subject.execute(project_from)

        expect(project_to.project_group_links.count).to eq group_links_count
      end

      it 'moves memberships and authorizations' do
        members_count = project_from.project_members.count
        project_authorizations = project_from.project_authorizations.count

        subject.execute(project_from)

        expect(project_to.project_members.count).to eq members_count
        expect(project_to.project_authorizations.count).to eq project_authorizations
      end

      context 'moves lfs objects relationships' do
        before do
          create_list(:lfs_objects_project, 3, project: project_from)
        end

        it do
          lfs_objects_count = project_from.lfs_objects.count

          subject.execute(project_from)

          expect(project_to.lfs_objects.count).to eq lfs_objects_count
        end
      end

      it 'removes the original project' do
        subject.execute(project_from)

        expect { Project.find(project_from.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'renames the project' do
        subject.execute(project_from)

        expect(project_to.full_path).to eq project_from.full_path
      end
    end

    context 'when project does not have any relation' do
      it_behaves_like 'overwrite actions'
    end

    context 'when project with elements' do
      it_behaves_like 'overwrite actions' do
        let(:master_user) { create(:user) }
        let(:reporter_user) { create(:user) }
        let(:developer_user) { create(:user) }
        let(:master_group) { create(:group) }
        let(:reporter_group) { create(:group) }
        let(:developer_group) { create(:group) }

        before do
          create_list(:deploy_keys_project, 2, project: project_from)
          create_list(:notification_setting, 2, source: project_from)
          create_list(:users_star_project, 2, project: project_from)
          project_from.project_group_links.create(group: master_group, group_access: Gitlab::Access::MASTER)
          project_from.project_group_links.create(group: developer_group, group_access: Gitlab::Access::DEVELOPER)
          project_from.project_group_links.create(group: reporter_group, group_access: Gitlab::Access::REPORTER)
          project_from.add_master(master_user)
          project_from.add_developer(developer_user)
          project_from.add_reporter(reporter_user)
        end
      end
    end

    context 'forks' do
      context 'when moving a root forked project' do
        it 'moves the descendant forks' do
          expect(project_from.forks.count).to eq 2
          expect(project_to.forks.count).to eq 0

          subject.execute(project_from)

          expect(project_from.forks.count).to eq 0
          expect(project_to.forks.count).to eq 2
          expect(lvl1_forked_project_1.forked_from_project).to eq project_to
          expect(lvl1_forked_project_1.fork_network_member.forked_from_project).to eq project_to
          expect(lvl1_forked_project_2.forked_from_project).to eq project_to
          expect(lvl1_forked_project_2.fork_network_member.forked_from_project).to eq project_to
        end

        it 'updates the fork network' do
          expect(project_from.fork_network.root_project).to eq project_from
          expect(project_from.fork_network.fork_network_members.map(&:project)).to include project_from

          subject.execute(project_from)

          expect(project_to.reload.fork_network.root_project).to eq project_to
          expect(project_to.fork_network.fork_network_members.map(&:project)).not_to include project_from
        end
      end
      context 'when moving a intermediate forked project' do
        let(:project_to) { create(:project, namespace: lvl1_forked_project_1.namespace) }

        it 'moves the descendant forks' do
          expect(lvl1_forked_project_1.forks.count).to eq 2
          expect(project_to.forks.count).to eq 0

          subject.execute(lvl1_forked_project_1)

          expect(lvl1_forked_project_1.forks.count).to eq 0
          expect(project_to.forks.count).to eq 2
          expect(lvl2_forked_project_1_1.forked_from_project).to eq project_to
          expect(lvl2_forked_project_1_1.fork_network_member.forked_from_project).to eq project_to
          expect(lvl2_forked_project_1_2.forked_from_project).to eq project_to
          expect(lvl2_forked_project_1_2.fork_network_member.forked_from_project).to eq project_to
        end

        it 'moves the ascendant fork' do
          subject.execute(lvl1_forked_project_1)

          expect(project_to.reload.forked_from_project).to eq project_from
          expect(project_to.fork_network_member.forked_from_project).to eq project_from
        end

        it 'does not update fork network' do
          subject.execute(lvl1_forked_project_1)

          expect(project_to.reload.fork_network.root_project).to eq project_from
        end
      end
    end

    context 'if an exception is raised' do
      it 'rollbacks changes' do
        updated_at = project_from.updated_at

        allow(subject).to receive(:rename_project).and_raise(StandardError)

        expect { subject.execute(project_from) }.to raise_error(StandardError)
        expect(Project.find(project_from.id)).not_to be_nil
        expect(project_from.reload.updated_at.change(usec: 0)).to eq updated_at.change(usec: 0)
      end

      it 'tries to restore the original project repositories' do
        allow(subject).to receive(:rename_project).and_raise(StandardError)

        expect(subject).to receive(:attempt_restore_repositories).with(project_from)

        expect { subject.execute(project_from) }.to raise_error(StandardError)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OverwriteProjectService, feature_category: :groups_and_projects do
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
    project_to.project_feature.reload

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

      it 'schedules original project for deletion' do
        expect_next_instance_of(Projects::DestroyService) do |service|
          expect(service).to receive(:async_execute)
        end

        subject.execute(project_from)
      end

      it 'renames the project' do
        original_path = project_from.full_path

        subject.execute(project_from)

        expect(project_to.full_path).to eq(original_path)
      end

      it 'renames source project to temp name' do
        allow(SecureRandom).to receive(:hex).and_return('test')

        subject.execute(project_from)

        expect(project_from.full_path).to include('-old-test')
      end

      context 'when project rename fails' do
        before do
          expect(subject).to receive(:move_relationships_between).with(project_from, project_to)
          expect(subject).to receive(:move_relationships_between).with(project_to, project_from)
        end

        context 'source rename' do
          it 'moves relations back to source project and raises an exception' do
            allow(subject).to receive(:rename_project).and_return(status: :error)

            expect { subject.execute(project_from) }.to raise_error(StandardError, 'Source project rename failed during project overwrite')
          end
        end

        context 'new project rename' do
          it 'moves relations back, renames source project back to original name and raises' do
            name = project_from.name
            path = project_from.path

            allow(subject).to receive(:rename_project).and_call_original
            allow(subject).to receive(:rename_project).with(project_to, name, path).and_return(status: :error)

            expect { subject.execute(project_from) }.to raise_error(StandardError, 'New project rename failed during project overwrite')

            expect(project_from.name).to eq(name)
            expect(project_from.path).to eq(path)
          end
        end
      end
    end

    context 'when project does not have any relation' do
      it_behaves_like 'overwrite actions'
    end

    context 'when project with elements' do
      it_behaves_like 'overwrite actions' do
        let(:maintainer_user) { create(:user) }
        let(:reporter_user) { create(:user) }
        let(:developer_user) { create(:user) }
        let(:maintainer_group) { create(:group) }
        let(:reporter_group) { create(:group) }
        let(:developer_group) { create(:group) }

        before do
          create_list(:deploy_keys_project, 2, project: project_from)
          create_list(:notification_setting, 2, source: project_from)
          create_list(:users_star_project, 2, project: project_from)
          project_from.project_group_links.create!(group: maintainer_group, group_access: Gitlab::Access::MAINTAINER)
          project_from.project_group_links.create!(group: developer_group, group_access: Gitlab::Access::DEVELOPER)
          project_from.project_group_links.create!(group: reporter_group, group_access: Gitlab::Access::REPORTER)
          project_from.add_maintainer(maintainer_user)
          project_from.add_developer(developer_user)
          project_from.add_reporter(reporter_user)
        end
      end
    end

    context 'forks', :sidekiq_inline do
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
      before do
        allow(subject).to receive(:rename_project).and_raise(StandardError)
      end

      it 'rollbacks changes' do
        updated_at = project_from.updated_at

        expect { subject.execute(project_from) }.to raise_error(StandardError)
        expect(Project.find(project_from.id)).not_to be_nil
        expect(project_from.reload.updated_at.change(usec: 0)).to eq updated_at.change(usec: 0)
      end

      it 'removes fork network member' do
        expect(ForkNetworkMember).to receive(:create!)
        expect(ForkNetworkMember).to receive(:find_by)
        expect(subject).to receive(:remove_source_project_from_fork_network).and_call_original

        expect { subject.execute(project_from) }.to raise_error(StandardError)

        expect(project_from.fork_network_member).to be_nil
      end
    end
  end
end

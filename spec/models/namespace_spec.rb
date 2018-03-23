require 'spec_helper'

describe Namespace do
  include ProjectForksHelper

  let!(:namespace) { create(:namespace) }
  let(:gitlab_shell) { Gitlab::Shell.new }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :project_statistics }
    it { is_expected.to belong_to :parent }
    it { is_expected.to have_many :children }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_presence_of(:owner) }

    it 'does not allow too deep nesting' do
      ancestors = (1..21).to_a
      nested = build(:namespace, parent: namespace)

      allow(nested).to receive(:ancestors).and_return(ancestors)

      expect(nested).not_to be_valid
      expect(nested.errors[:parent_id].first).to eq('has too deep level of nesting')
    end

    describe 'reserved path validation' do
      context 'nested group' do
        let(:group) { build(:group, :nested, path: 'tree') }

        it { expect(group).not_to be_valid }

        it 'rejects nested paths' do
          parent = create(:group, :nested, path: 'environments')
          namespace = build(:group, path: 'folders', parent: parent)

          expect(namespace).not_to be_valid
        end
      end

      context "is case insensitive" do
        let(:group) { build(:group, path: "Groups") }

        it { expect(group).not_to be_valid }
      end

      context 'top-level group' do
        let(:group) { build(:group, path: 'tree') }

        it { expect(group).to be_valid }
      end
    end
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:human_name) }
    it { is_expected.to respond_to(:to_param) }
    it { is_expected.to respond_to(:has_parent?) }
  end

  describe 'inclusions' do
    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
  end

  describe '#visibility_level_field' do
    it { expect(namespace.visibility_level_field).to eq(:visibility_level) }
  end

  describe '#to_param' do
    it { expect(namespace.to_param).to eq(namespace.full_path) }
  end

  describe '#human_name' do
    it { expect(namespace.human_name).to eq(namespace.owner_name) }
  end

  describe '.search' do
    let(:namespace) { create(:namespace) }

    it 'returns namespaces with a matching name' do
      expect(described_class.search(namespace.name)).to eq([namespace])
    end

    it 'returns namespaces with a partially matching name' do
      expect(described_class.search(namespace.name[0..2])).to eq([namespace])
    end

    it 'returns namespaces with a matching name regardless of the casing' do
      expect(described_class.search(namespace.name.upcase)).to eq([namespace])
    end

    it 'returns namespaces with a matching path' do
      expect(described_class.search(namespace.path)).to eq([namespace])
    end

    it 'returns namespaces with a partially matching path' do
      expect(described_class.search(namespace.path[0..2])).to eq([namespace])
    end

    it 'returns namespaces with a matching path regardless of the casing' do
      expect(described_class.search(namespace.path.upcase)).to eq([namespace])
    end
  end

  describe '.with_statistics' do
    let(:namespace) { create :namespace }

    let(:project1) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               storage_size:         606,
                               repository_size:      101,
                               lfs_objects_size:     202,
                               build_artifacts_size: 303))
    end

    let(:project2) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               storage_size:         60,
                               repository_size:      10,
                               lfs_objects_size:     20,
                               build_artifacts_size: 30))
    end

    it "sums all project storage counters in the namespace" do
      project1
      project2
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 666
      expect(statistics.repository_size).to eq 111
      expect(statistics.lfs_objects_size).to eq 222
      expect(statistics.build_artifacts_size).to eq 333
    end

    it "correctly handles namespaces without projects" do
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 0
      expect(statistics.repository_size).to eq 0
      expect(statistics.lfs_objects_size).to eq 0
      expect(statistics.build_artifacts_size).to eq 0
    end
  end

  describe '#ancestors_upto', :nested_groups do
    let(:parent) { create(:group) }
    let(:child) { create(:group, parent: parent) }
    let(:child2) { create(:group, parent: child) }

    it 'returns all ancestors when no namespace is given' do
      expect(child2.ancestors_upto).to contain_exactly(child, parent)
    end

    it 'includes ancestors upto but excluding the given ancestor' do
      expect(child2.ancestors_upto(parent)).to contain_exactly(child)
    end
  end

  describe '#move_dir', :request_store do
    shared_examples "namespace restrictions" do
      context "when any project has container images" do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])

          create(:project, namespace: namespace, container_repositories: [container_repository])

          allow(namespace).to receive(:path_was).and_return(namespace.path)
          allow(namespace).to receive(:path).and_return('new_path')
        end

        it 'raises an error about not movable project' do
          expect { namespace.move_dir }.to raise_error(/Namespace cannot be moved/)
        end
      end
    end

    context 'legacy storage' do
      let(:namespace) { create(:namespace) }
      let!(:project) { create(:project_empty_repo, :legacy_storage, namespace: namespace) }

      it_behaves_like 'namespace restrictions'

      it "raises error when directory exists" do
        expect { namespace.move_dir }.to raise_error("namespace directory cannot be moved")
      end

      it "moves dir if path changed" do
        namespace.update_attributes(path: namespace.full_path + '_new')

        expect(gitlab_shell.exists?(project.repository_storage_path, "#{namespace.path}/#{project.path}.git")).to be_truthy
      end

      context 'with subgroups', :nested_groups do
        let(:parent) { create(:group, name: 'parent', path: 'parent') }
        let(:new_parent) { create(:group, name: 'new_parent', path: 'new_parent') }
        let(:child) { create(:group, name: 'child', path: 'child', parent: parent) }
        let!(:project) { create(:project_empty_repo, :legacy_storage, path: 'the-project', namespace: child, skip_disk_validation: true) }
        let(:uploads_dir) { FileUploader.root }
        let(:pages_dir) { File.join(TestEnv.pages_path) }

        def expect_project_directories_at(namespace_path)
          expected_repository_path = File.join(TestEnv.repos_path, namespace_path, 'the-project.git')
          expected_upload_path = File.join(uploads_dir, namespace_path, 'the-project')
          expected_pages_path = File.join(pages_dir, namespace_path, 'the-project')

          expect(File.directory?(expected_repository_path)).to be_truthy
          expect(File.directory?(expected_upload_path)).to be_truthy
          expect(File.directory?(expected_pages_path)).to be_truthy
        end

        before do
          FileUtils.mkdir_p(File.join(TestEnv.repos_path, "#{project.full_path}.git"))
          FileUtils.mkdir_p(File.join(uploads_dir, project.full_path))
          FileUtils.mkdir_p(File.join(pages_dir, project.full_path))
        end

        context 'renaming child' do
          it 'correctly moves the repository, uploads and pages' do
            child.update!(path: 'renamed')

            expect_project_directories_at('parent/renamed')
          end
        end

        context 'renaming parent' do
          it 'correctly moves the repository, uploads and pages' do
            parent.update!(path: 'renamed')

            expect_project_directories_at('renamed/child')
          end
        end

        context 'moving from one parent to another' do
          it 'correctly moves the repository, uploads and pages' do
            child.update!(parent: new_parent)

            expect_project_directories_at('new_parent/child')
          end
        end

        context 'moving from having a parent to root' do
          it 'correctly moves the repository, uploads and pages' do
            child.update!(parent: nil)

            expect_project_directories_at('child')
          end
        end

        context 'moving from root to having a parent' do
          it 'correctly moves the repository, uploads and pages' do
            parent.update!(parent: new_parent)

            expect_project_directories_at('new_parent/parent/child')
          end
        end
      end
    end

    context 'hashed storage' do
      let(:namespace) { create(:namespace) }
      let!(:project) { create(:project_empty_repo, namespace: namespace) }

      it_behaves_like 'namespace restrictions'

      it "repository directory remains unchanged if path changed" do
        before_disk_path = project.disk_path
        namespace.update_attributes(path: namespace.full_path + '_new')

        expect(before_disk_path).to eq(project.disk_path)
        expect(gitlab_shell.exists?(project.repository_storage_path, "#{project.disk_path}.git")).to be_truthy
      end
    end

    it 'updates project full path in .git/config for each project inside namespace' do
      parent = create(:group, name: 'mygroup', path: 'mygroup')
      subgroup = create(:group, name: 'mysubgroup', path: 'mysubgroup', parent: parent)
      project_in_parent_group = create(:project, :legacy_storage, :repository, namespace: parent, name: 'foo1')
      hashed_project_in_subgroup = create(:project, :repository, namespace: subgroup, name: 'foo2')
      legacy_project_in_subgroup = create(:project, :legacy_storage, :repository, namespace: subgroup, name: 'foo3')

      parent.update(path: 'mygroup_new')

      expect(project_rugged(project_in_parent_group).config['gitlab.fullpath']).to eq "mygroup_new/#{project_in_parent_group.path}"
      expect(project_rugged(hashed_project_in_subgroup).config['gitlab.fullpath']).to eq "mygroup_new/mysubgroup/#{hashed_project_in_subgroup.path}"
      expect(project_rugged(legacy_project_in_subgroup).config['gitlab.fullpath']).to eq "mygroup_new/mysubgroup/#{legacy_project_in_subgroup.path}"
    end

    def project_rugged(project)
      project.repository.rugged
    end
  end

  describe '#actual_size_limit' do
    let(:namespace) { build(:namespace) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the correct size limit' do
      expect(namespace.actual_size_limit).to eq(50)
    end
  end

  describe '#rm_dir', 'callback' do
    let(:repository_storage_path) { Gitlab.config.repositories.storages.default.legacy_disk_path }
    let(:path_in_dir) { File.join(repository_storage_path, namespace.full_path) }
    let(:deleted_path) { namespace.full_path.gsub(namespace.path, "#{namespace.full_path}+#{namespace.id}+deleted") }
    let(:deleted_path_in_dir) { File.join(repository_storage_path, deleted_path) }

    context 'legacy storage' do
      let!(:project) { create(:project_empty_repo, :legacy_storage, namespace: namespace) }

      it 'renames its dirs when deleted' do
        allow(GitlabShellWorker).to receive(:perform_in)

        namespace.destroy

        expect(File.exist?(deleted_path_in_dir)).to be(true)
      end

      it 'schedules the namespace for deletion' do
        expect(GitlabShellWorker).to receive(:perform_in).with(5.minutes, :rm_namespace, repository_storage_path, deleted_path)

        namespace.destroy
      end

      context 'in sub-groups' do
        let(:parent) { create(:group, path: 'parent') }
        let(:child) { create(:group, parent: parent, path: 'child') }
        let!(:project) { create(:project_empty_repo, :legacy_storage, namespace: child) }
        let(:path_in_dir) { File.join(repository_storage_path, 'parent', 'child') }
        let(:deleted_path) { File.join('parent', "child+#{child.id}+deleted") }
        let(:deleted_path_in_dir) { File.join(repository_storage_path, deleted_path) }

        it 'renames its dirs when deleted' do
          allow(GitlabShellWorker).to receive(:perform_in)

          child.destroy

          expect(File.exist?(deleted_path_in_dir)).to be(true)
        end

        it 'schedules the namespace for deletion' do
          expect(GitlabShellWorker).to receive(:perform_in).with(5.minutes, :rm_namespace, repository_storage_path, deleted_path)

          child.destroy
        end
      end

      it 'removes the exports folder' do
        expect(namespace).to receive(:remove_exports!)

        namespace.destroy
      end
    end

    context 'hashed storage' do
      let!(:project) { create(:project_empty_repo, namespace: namespace) }

      it 'has no repositories base directories to remove' do
        allow(GitlabShellWorker).to receive(:perform_in)

        expect(File.exist?(path_in_dir)).to be(false)

        namespace.destroy

        expect(File.exist?(deleted_path_in_dir)).to be(false)
      end

      it 'removes the exports folder' do
        expect(namespace).to receive(:remove_exports!)

        namespace.destroy
      end
    end
  end

  describe '.find_by_path_or_name' do
    before do
      @namespace = create(:namespace, name: 'WoW', path: 'woW')
    end

    it { expect(described_class.find_by_path_or_name('wow')).to eq(@namespace) }
    it { expect(described_class.find_by_path_or_name('WOW')).to eq(@namespace) }
    it { expect(described_class.find_by_path_or_name('unknown')).to eq(nil) }
  end

  describe ".clean_path" do
    let!(:user)       { create(:user, username: "johngitlab-etc") }
    let!(:namespace)  { create(:namespace, path: "JohnGitLab-etc1") }

    it "cleans the path and makes sure it's available" do
      expect(described_class.clean_path("-john+gitlab-ETC%.git@gmail.com")).to eq("johngitlab-ETC2")
      expect(described_class.clean_path("--%+--valid_*&%name=.git.%.atom.atom.@email.com")).to eq("valid_name")
    end
  end

  describe '#ancestors', :nested_groups do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.ancestors).to include(group, nested_group, deep_nested_group)
      expect(deep_nested_group.ancestors).to include(group, nested_group)
      expect(nested_group.ancestors).to include(group)
      expect(group.ancestors).to eq([])
    end
  end

  describe '#self_and_ancestors', :nested_groups do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(nested_group.self_and_ancestors).to contain_exactly(group, nested_group)
      expect(group.self_and_ancestors).to contain_exactly(group)
    end
  end

  describe '#descendants', :nested_groups do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.descendants.to_a).to eq([])
      expect(deep_nested_group.descendants.to_a).to include(very_deep_nested_group)
      expect(nested_group.descendants.to_a).to include(deep_nested_group, very_deep_nested_group)
      expect(group.descendants.to_a).to include(nested_group, deep_nested_group, very_deep_nested_group)
    end
  end

  describe '#self_and_descendants', :nested_groups do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.self_and_descendants).to contain_exactly(very_deep_nested_group)
      expect(deep_nested_group.self_and_descendants).to contain_exactly(deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_descendants).to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group)
      expect(group.self_and_descendants).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end
  end

  describe '#users_with_descendants', :nested_groups do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }

    it 'returns member users on every nest level without duplication' do
      group.add_developer(user_a)
      nested_group.add_developer(user_b)
      deep_nested_group.add_developer(user_a)

      expect(group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(nested_group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(deep_nested_group.users_with_descendants).to contain_exactly(user_a)
    end
  end

  describe '#user_ids_for_project_authorizations' do
    it 'returns the user IDs for which to refresh authorizations' do
      expect(namespace.user_ids_for_project_authorizations)
        .to eq([namespace.owner_id])
    end
  end

  describe '#all_projects' do
    let(:group) { create(:group) }
    let(:child) { create(:group, parent: group) }
    let!(:project1) { create(:project_empty_repo, namespace: group) }
    let!(:project2) { create(:project_empty_repo, namespace: child) }

    it { expect(group.all_projects.to_a).to match_array([project2, project1]) }
  end

  describe '#share_with_group_lock with subgroups', :nested_groups do
    context 'when creating a subgroup' do
      let(:subgroup) { create(:group, parent: root_group )}

      context 'under a parent with "Share with group lock" enabled' do
        let(:root_group) { create(:group, share_with_group_lock: true) }

        it 'enables "Share with group lock" on the subgroup' do
          expect(subgroup.share_with_group_lock).to be_truthy
        end
      end

      context 'under a parent with "Share with group lock" disabled' do
        let(:root_group) { create(:group) }

        it 'does not enable "Share with group lock" on the subgroup' do
          expect(subgroup.share_with_group_lock).to be_falsey
        end
      end
    end

    context 'when enabling the parent group "Share with group lock"' do
      let(:root_group) { create(:group) }
      let!(:subgroup) { create(:group, parent: root_group )}

      it 'the subgroup "Share with group lock" becomes enabled' do
        root_group.update!(share_with_group_lock: true)

        expect(subgroup.reload.share_with_group_lock).to be_truthy
      end
    end

    context 'when disabling the parent group "Share with group lock" (which was already enabled)' do
      let(:root_group) { create(:group, share_with_group_lock: true) }

      context 'and the subgroup "Share with group lock" is enabled' do
        let(:subgroup) { create(:group, parent: root_group, share_with_group_lock: true )}

        it 'the subgroup "Share with group lock" does not change' do
          root_group.update!(share_with_group_lock: false)

          expect(subgroup.reload.share_with_group_lock).to be_truthy
        end
      end

      context 'but the subgroup "Share with group lock" is disabled' do
        let(:subgroup) { create(:group, parent: root_group )}

        it 'the subgroup "Share with group lock" does not change' do
          root_group.update!(share_with_group_lock: false)

          expect(subgroup.reload.share_with_group_lock?).to be_falsey
        end
      end
    end

    context 'when a group is transferred into a root group' do
      context 'when the root group "Share with group lock" is enabled' do
        let(:root_group) { create(:group, share_with_group_lock: true) }

        context 'when the subgroup "Share with group lock" is enabled' do
          let(:subgroup) { create(:group, share_with_group_lock: true )}

          it 'the subgroup "Share with group lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end

        context 'when the subgroup "Share with group lock" is disabled' do
          let(:subgroup) { create(:group)}

          it 'the subgroup "Share with group lock" becomes enabled' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end
      end

      context 'when the root group "Share with group lock" is disabled' do
        let(:root_group) { create(:group) }

        context 'when the subgroup "Share with group lock" is enabled' do
          let(:subgroup) { create(:group, share_with_group_lock: true )}

          it 'the subgroup "Share with group lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end

        context 'when the subgroup "Share with group lock" is disabled' do
          let(:subgroup) { create(:group)}

          it 'the subgroup "Share with group lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_falsey
          end
        end
      end
    end
  end

  describe '#membership_lock with subgroups', :nested_groups do
    context 'when creating a subgroup' do
      let(:subgroup) { create(:group, parent: root_group) }

      context 'under a parent with "Membership lock" enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        it 'enables "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_truthy
        end
      end

      context 'under a parent with "Membership lock" disabled' do
        let(:root_group) { create(:group) }

        it 'does not enable "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_falsey
        end
      end

      context 'when enabling the parent group "Membership lock"' do
        let(:root_group) { create(:group) }
        let!(:subgroup) { create(:group, parent: root_group) }

        it 'the subgroup "Membership lock" not changed' do
          root_group.update!(membership_lock: true)

          expect(subgroup.reload.membership_lock).to be_falsey
        end
      end

      context 'when disabling the parent group "Membership lock" (which was already enabled)' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'and the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, parent: root_group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock).to be_truthy
          end
        end

        context 'but the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group, parent: root_group) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock?).to be_falsey
          end
        end
      end
    end

    # Note: Group transfers are not yet implemented
    context 'when a group is transferred into a root group' do
      context 'when the root group "Membership lock" is enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" not changed' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end

      context 'when the root group "Membership lock" is disabled' do
        let(:root_group) { create(:group) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end
    end
  end

  describe '#find_fork_of?' do
    let(:project) { create(:project, :public) }
    let!(:forked_project) { fork_project(project, namespace.owner, namespace: namespace) }

    before do
      # Reset the fork network relation
      project.reload
    end

    it 'knows if there is a direct fork in the namespace' do
      expect(namespace.find_fork_of(project)).to eq(forked_project)
    end

    it 'knows when there is as fork-of-fork in the namespace' do
      other_namespace = create(:namespace)
      other_fork = fork_project(forked_project, other_namespace.owner, namespace: other_namespace)

      expect(other_namespace.find_fork_of(project)).to eq(other_fork)
    end

    context 'with request store enabled', :request_store do
      it 'only queries once' do
        expect(project.fork_network).to receive(:find_forks_in).once.and_call_original

        2.times { namespace.find_fork_of(project) }
      end
    end
  end

  describe '#root_ancestor' do
    it 'returns the top most ancestor', :nested_groups do
      root_group = create(:group)
      nested_group = create(:group, parent: root_group)
      deep_nested_group = create(:group, parent: nested_group)
      very_deep_nested_group = create(:group, parent: deep_nested_group)

      expect(nested_group.root_ancestor).to eq(root_group)
      expect(deep_nested_group.root_ancestor).to eq(root_group)
      expect(very_deep_nested_group.root_ancestor).to eq(root_group)
    end
  end

  describe '#remove_exports' do
    let(:legacy_project) { create(:project, :with_export, :legacy_storage, namespace: namespace) }
    let(:hashed_project) { create(:project, :with_export, namespace: namespace) }
    let(:export_path) { Dir.mktmpdir('namespace_remove_exports_spec') }
    let(:legacy_export) { legacy_project.export_project_path }
    let(:hashed_export) { hashed_project.export_project_path }

    it 'removes exports for legacy and hashed projects' do
      allow(Gitlab::ImportExport).to receive(:storage_path) { export_path }

      expect(File.exist?(legacy_export)).to be_truthy
      expect(File.exist?(hashed_export)).to be_truthy

      namespace.remove_exports!

      expect(File.exist?(legacy_export)).to be_falsy
      expect(File.exist?(hashed_export)).to be_falsy
    end
  end

  describe '#full_path_was' do
    context 'when the group has no parent' do
      it 'should return the path was' do
        group = create(:group, parent: nil)
        expect(group.full_path_was).to eq(group.path_was)
      end
    end

    context 'when a parent is assigned to a group with no previous parent' do
      it 'should return the path was' do
        group = create(:group, parent: nil)

        parent = create(:group)
        group.parent = parent

        expect(group.full_path_was).to eq("#{group.path_was}")
      end
    end

    context 'when a parent is removed from the group' do
      it 'should return the parent full path' do
        parent = create(:group)
        group = create(:group, parent: parent)
        group.parent = nil

        expect(group.full_path_was).to eq("#{parent.full_path}/#{group.path}")
      end
    end

    context 'when changing parents' do
      it 'should return the previous parent full path' do
        parent = create(:group)
        group = create(:group, parent: parent)
        new_parent = create(:group)
        group.parent = new_parent
        expect(group.full_path_was).to eq("#{parent.full_path}/#{group.path}")
      end
    end
  end
end

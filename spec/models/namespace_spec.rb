# frozen_string_literal: true

require 'spec_helper'

describe Namespace do
  include ProjectForksHelper
  include GitHelpers

  let!(:namespace) { create(:namespace) }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:repository_storage) { 'default' }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :project_statistics }
    it { is_expected.to belong_to :parent }
    it { is_expected.to have_many :children }
    it { is_expected.to have_one :root_storage_statistics }
    it { is_expected.to have_one :aggregation_schedule }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }

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

  describe 'delegate' do
    it { is_expected.to delegate_method(:name).to(:owner).with_prefix.with_arguments(allow_nil: true) }
    it { is_expected.to delegate_method(:avatar_url).to(:owner).with_arguments(allow_nil: true) }
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

  describe '#first_project_with_container_registry_tags' do
    let(:container_repository) { create(:container_repository) }
    let!(:project) { create(:project, namespace: namespace, container_repositories: [container_repository]) }

    before do
      stub_container_registry_config(enabled: true)
    end

    it 'returns the project' do
      stub_container_registry_tags(repository: :any, tags: ['tag'])

      expect(namespace.first_project_with_container_registry_tags).to eq(project)
    end

    it 'returns no project' do
      stub_container_registry_tags(repository: :any, tags: nil)

      expect(namespace.first_project_with_container_registry_tags).to be_nil
    end
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
                               repository_size:      101,
                               wiki_size:            505,
                               lfs_objects_size:     202,
                               build_artifacts_size: 303,
                               packages_size:        404))
    end

    let(:project2) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               repository_size:      10,
                               wiki_size:            50,
                               lfs_objects_size:     20,
                               build_artifacts_size: 30,
                               packages_size:        40))
    end

    it "sums all project storage counters in the namespace" do
      project1
      project2
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 1665
      expect(statistics.repository_size).to eq 111
      expect(statistics.wiki_size).to eq 555
      expect(statistics.lfs_objects_size).to eq 222
      expect(statistics.build_artifacts_size).to eq 333
      expect(statistics.packages_size).to eq 444
    end

    it "correctly handles namespaces without projects" do
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 0
      expect(statistics.repository_size).to eq 0
      expect(statistics.wiki_size).to eq 0
      expect(statistics.lfs_objects_size).to eq 0
      expect(statistics.build_artifacts_size).to eq 0
      expect(statistics.packages_size).to eq 0
    end
  end

  describe '.find_by_pages_host' do
    it 'finds namespace by GitLab Pages host and is case-insensitive' do
      namespace = create(:namespace, name: 'topnamespace')
      create(:namespace, name: 'annother_namespace')
      host = "TopNamespace.#{Settings.pages.host.upcase}"

      expect(described_class.find_by_pages_host(host)).to eq(namespace)
    end

    it "returns no result if the provided host is not subdomain of the Pages host" do
      create(:namespace, name: 'namespace.io')
      host = "namespace.io"

      expect(described_class.find_by_pages_host(host)).to eq(nil)
    end
  end

  describe '#ancestors_upto' do
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
          expect { namespace.move_dir }.to raise_error(Gitlab::UpdatePathError,
                                                       /Namespace .* cannot be moved/)
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
        namespace.update(path: namespace.full_path + '_new')

        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{namespace.path}/#{project.path}.git")).to be_truthy
      end

      context 'when #write_projects_repository_config raises an error' do
        context 'in test environment' do
          it 'raises an exception' do
            expect(namespace).to receive(:write_projects_repository_config).and_raise('foo')

            expect do
              namespace.update(path: namespace.full_path + '_new')
            end.to raise_error('foo')
          end
        end

        context 'in production environment' do
          it 'does not cancel later callbacks' do
            expect(namespace).to receive(:write_projects_repository_config).and_raise('foo')
            expect(namespace).to receive(:move_dir).and_wrap_original do |m, *args|
              move_dir_result = m.call(*args)

              expect(move_dir_result).to be_truthy # Must be truthy, or else later callbacks would be canceled

              move_dir_result
            end
            expect(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false) # like prod

            namespace.update(path: namespace.full_path + '_new')
          end
        end
      end

      shared_examples 'move_dir without repository storage feature' do |storage_version|
        let(:namespace) { create(:namespace) }
        let(:gitlab_shell) { namespace.gitlab_shell }
        let!(:project) { create(:project_empty_repo, namespace: namespace, storage_version: storage_version) }

        it 'calls namespace service' do
          expect(gitlab_shell).to receive(:add_namespace).and_return(true)
          expect(gitlab_shell).to receive(:mv_namespace).and_return(true)

          namespace.move_dir
        end
      end

      shared_examples 'move_dir with repository storage feature' do |storage_version|
        let(:namespace) { create(:namespace) }
        let(:gitlab_shell) { namespace.gitlab_shell }
        let!(:project) { create(:project_empty_repo, namespace: namespace, storage_version: storage_version) }

        it 'does not call namespace service' do
          expect(gitlab_shell).not_to receive(:add_namespace)
          expect(gitlab_shell).not_to receive(:mv_namespace)

          namespace.move_dir
        end
      end

      context 'project is without repository storage feature' do
        [nil, 0].each do |storage_version|
          it_behaves_like 'move_dir without repository storage feature', storage_version
        end
      end

      context 'project has repository storage feature' do
        [1, 2].each do |storage_version|
          it_behaves_like 'move_dir with repository storage feature', storage_version
        end
      end

      context 'with subgroups' do
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
        namespace.update(path: namespace.full_path + '_new')

        expect(before_disk_path).to eq(project.disk_path)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy
      end
    end

    context 'for each project inside the namespace' do
      let!(:parent) { create(:group, name: 'mygroup', path: 'mygroup') }
      let!(:subgroup) { create(:group, name: 'mysubgroup', path: 'mysubgroup', parent: parent) }
      let!(:project_in_parent_group) { create(:project, :legacy_storage, :repository, namespace: parent, name: 'foo1') }
      let!(:hashed_project_in_subgroup) { create(:project, :repository, namespace: subgroup, name: 'foo2') }
      let!(:legacy_project_in_subgroup) { create(:project, :legacy_storage, :repository, namespace: subgroup, name: 'foo3') }

      it 'updates project full path in .git/config' do
        parent.update(path: 'mygroup_new')

        expect(project_rugged(project_in_parent_group).config['gitlab.fullpath']).to eq "mygroup_new/#{project_in_parent_group.path}"
        expect(project_rugged(hashed_project_in_subgroup).config['gitlab.fullpath']).to eq "mygroup_new/mysubgroup/#{hashed_project_in_subgroup.path}"
        expect(project_rugged(legacy_project_in_subgroup).config['gitlab.fullpath']).to eq "mygroup_new/mysubgroup/#{legacy_project_in_subgroup.path}"
      end

      it 'updates the project storage location' do
        repository_project_in_parent_group = create(:project_repository, project: project_in_parent_group)
        repository_hashed_project_in_subgroup = create(:project_repository, project: hashed_project_in_subgroup)
        repository_legacy_project_in_subgroup = create(:project_repository, project: legacy_project_in_subgroup)

        parent.update(path: 'mygroup_moved')

        expect(repository_project_in_parent_group.reload.disk_path).to eq "mygroup_moved/#{project_in_parent_group.path}"
        expect(repository_hashed_project_in_subgroup.reload.disk_path).to eq hashed_project_in_subgroup.disk_path
        expect(repository_legacy_project_in_subgroup.reload.disk_path).to eq "mygroup_moved/mysubgroup/#{legacy_project_in_subgroup.path}"
      end

      def project_rugged(project)
        # Routes are loaded when creating the projects, so we need to manually
        # reload them for the below code to be aware of the above UPDATE.
        project.route.reload

        rugged_repo(project.repository)
      end
    end
  end

  describe '#rm_dir', 'callback' do
    let(:repository_storage_path) do
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        Gitlab.config.repositories.storages.default.legacy_disk_path
      end
    end
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
        expect(GitlabShellWorker).to receive(:perform_in).with(5.minutes, :rm_namespace, repository_storage, deleted_path)

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
          expect(GitlabShellWorker).to receive(:perform_in).with(5.minutes, :rm_namespace, repository_storage, deleted_path)

          child.destroy
        end
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

  describe '#self_and_hierarchy' do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct tree' do
      expect(group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(very_deep_nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end
  end

  describe '#ancestors' do
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

  describe '#self_and_ancestors' do
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

  describe '#descendants' do
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

  describe '#self_and_descendants' do
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

  describe '#users_with_descendants' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }

    it 'returns member users on every nest level without duplication' do
      group.add_developer(user_a)
      nested_group.add_developer(user_b)
      deep_nested_group.add_maintainer(user_a)

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
    it { expect(child.all_projects.to_a).to match_array([project2]) }
  end

  describe '#all_pipelines' do
    let(:group) { create(:group) }
    let(:child) { create(:group, parent: group) }
    let!(:project1) { create(:project_empty_repo, namespace: group) }
    let!(:project2) { create(:project_empty_repo, namespace: child) }
    let!(:pipeline1) { create(:ci_empty_pipeline, project: project1) }
    let!(:pipeline2) { create(:ci_empty_pipeline, project: project2) }

    it { expect(group.all_pipelines.to_a).to match_array([pipeline1, pipeline2]) }
  end

  describe '#share_with_group_lock with subgroups' do
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
    it 'returns the top most ancestor' do
      root_group = create(:group)
      nested_group = create(:group, parent: root_group)
      deep_nested_group = create(:group, parent: nested_group)
      very_deep_nested_group = create(:group, parent: deep_nested_group)

      expect(root_group.root_ancestor).to eq(root_group)
      expect(nested_group.root_ancestor).to eq(root_group)
      expect(deep_nested_group.root_ancestor).to eq(root_group)
      expect(very_deep_nested_group.root_ancestor).to eq(root_group)
    end
  end

  describe '#full_path_before_last_save' do
    context 'when the group has no parent' do
      it 'returns the path before last save' do
        group = create(:group)

        group.update(parent: nil)

        expect(group.full_path_before_last_save).to eq(group.path_before_last_save)
      end
    end

    context 'when a parent is assigned to a group with no previous parent' do
      it 'returns the path before last save' do
        group = create(:group, parent: nil)
        parent = create(:group)

        group.update(parent: parent)

        expect(group.full_path_before_last_save).to eq("#{group.path_before_last_save}")
      end
    end

    context 'when a parent is removed from the group' do
      it 'returns the parent full path' do
        parent = create(:group)
        group = create(:group, parent: parent)

        group.update(parent: nil)

        expect(group.full_path_before_last_save).to eq("#{parent.full_path}/#{group.path}")
      end
    end

    context 'when changing parents' do
      it 'returns the previous parent full path' do
        parent = create(:group)
        group = create(:group, parent: parent)
        new_parent = create(:group)

        group.update(parent: new_parent)

        expect(group.full_path_before_last_save).to eq("#{parent.full_path}/#{group.path}")
      end
    end
  end

  describe '#auto_devops_enabled' do
    context 'with users' do
      let(:user) { create(:user) }

      subject { user.namespace.auto_devops_enabled? }

      before do
        user.namespace.update!(auto_devops_enabled: auto_devops_enabled)
      end

      context 'when auto devops is explicitly enabled' do
        let(:auto_devops_enabled) { true }

        it { is_expected.to eq(true) }
      end

      context 'when auto devops is explicitly disabled' do
        let(:auto_devops_enabled) { false }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#user?' do
    subject { namespace.user? }

    context 'when type is a user' do
      let(:user) { create(:user) }
      let(:namespace) { user.namespace }

      it { is_expected.to be_truthy }
    end

    context 'when type is a group' do
      let(:namespace) { create(:group) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#aggregation_scheduled?' do
    let(:namespace) { create(:namespace) }

    subject { namespace.aggregation_scheduled? }

    context 'with an aggregation scheduled association' do
      let(:namespace) { create(:namespace, :with_aggregation_schedule) }

      it { is_expected.to be_truthy }
    end

    context 'without an aggregation scheduled association' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#emails_disabled?' do
    context 'when not a subgroup' do
      it 'returns false' do
        group = create(:group, emails_disabled: false)

        expect(group.emails_disabled?).to be_falsey
      end

      it 'returns true' do
        group = create(:group, emails_disabled: true)

        expect(group.emails_disabled?).to be_truthy
      end
    end

    context 'when a subgroup' do
      let(:grandparent) { create(:group) }
      let(:parent)      { create(:group, parent: grandparent) }
      let(:group)       { create(:group, parent: parent) }

      it 'returns false' do
        expect(group.emails_disabled?).to be_falsey
      end

      context 'when ancestor emails are disabled' do
        it 'returns true' do
          grandparent.update_attribute(:emails_disabled, true)

          expect(group.emails_disabled?).to be_truthy
        end
      end
    end
  end

  describe '#pages_virtual_domain' do
    let(:project) { create(:project, namespace: namespace) }

    context 'when there are pages deployed for the project' do
      context 'but pages metadata is not migrated' do
        before do
          generic_commit_status = create(:generic_commit_status, :success, stage: 'deploy', name: 'pages:deploy')
          generic_commit_status.update!(project: project)
          project.pages_metadatum.destroy!
        end

        it 'migrates pages metadata and returns the virual domain' do
          virtual_domain = namespace.pages_virtual_domain

          expect(project.reload.pages_metadatum.deployed).to eq(true)

          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.lookup_paths).not_to be_empty
        end
      end

      context 'and pages metadata is migrated' do
        before do
          project.mark_pages_as_deployed
        end

        it 'returns the virual domain' do
          virtual_domain = namespace.pages_virtual_domain

          expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
          expect(virtual_domain.lookup_paths).not_to be_empty
        end
      end
    end
  end

  describe '#has_parent?' do
    it 'returns true when the group has a parent' do
      group = create(:group, :nested)

      expect(group.has_parent?).to be_truthy
    end

    it 'returns true when the group has an unsaved parent' do
      parent = build(:group)
      group = build(:group, parent: parent)

      expect(group.has_parent?).to be_truthy
    end

    it 'returns false when the group has no parent' do
      group = create(:group, parent: nil)

      expect(group.has_parent?).to be_falsy
    end
  end

  describe '#closest_setting' do
    using RSpec::Parameterized::TableSyntax

    shared_examples_for 'fetching closest setting' do
      let!(:root_namespace) { create(:namespace) }
      let!(:namespace) { create(:namespace, parent: root_namespace) }

      let(:setting) { namespace.closest_setting(setting_name) }

      before do
        root_namespace.update_attribute(setting_name, root_setting)
        namespace.update_attribute(setting_name, child_setting)
      end

      it 'returns closest non-nil value' do
        expect(setting).to eq(result)
      end
    end

    context 'when setting is of non-boolean type' do
      where(:root_setting, :child_setting, :result) do
        100 | 200 | 200
        100 | nil | 100
        nil | nil | nil
      end

      with_them do
        let(:setting_name) { :max_artifacts_size }

        it_behaves_like 'fetching closest setting'
      end
    end

    context 'when setting is of boolean type' do
      where(:root_setting, :child_setting, :result) do
        true | false | false
        true | nil   | true
        nil  | nil   | nil
      end

      with_them do
        let(:setting_name) { :lfs_enabled }

        it_behaves_like 'fetching closest setting'
      end
    end
  end
end

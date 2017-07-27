require 'spec_helper'

describe Namespace do
  let!(:namespace) { create(:namespace) }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :project_statistics }
    it { is_expected.to belong_to :parent }
    it { is_expected.to have_many :children }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:parent_id) }
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
      create(:empty_project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               storage_size:         606,
                               repository_size:      101,
                               lfs_objects_size:     202,
                               build_artifacts_size: 303))
    end

    let(:project2) do
      create(:empty_project,
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

  describe '#move_dir' do
    before do
      @namespace = create :namespace
      @project = create(:project_empty_repo, namespace: @namespace)
      allow(@namespace).to receive(:path_changed?).and_return(true)
    end

    it "raises error when directory exists" do
      expect { @namespace.move_dir }.to raise_error("namespace directory cannot be moved")
    end

    it "moves dir if path changed" do
      new_path = @namespace.full_path + "_new"
      allow(@namespace).to receive(:full_path_was).and_return(@namespace.full_path)
      allow(@namespace).to receive(:full_path).and_return(new_path)
      expect(@namespace).to receive(:remove_exports!)
      expect(@namespace.move_dir).to be_truthy
    end

    context "when any project has container images" do
      let(:container_repository) { create(:container_repository) }

      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags(repository: :any, tags: ['tag'])

        create(:empty_project, namespace: @namespace, container_repositories: [container_repository])

        allow(@namespace).to receive(:path_was).and_return(@namespace.path)
        allow(@namespace).to receive(:path).and_return('new_path')
      end

      it 'raises an error about not movable project' do
        expect { @namespace.move_dir }.to raise_error(/Namespace cannot be moved/)
      end
    end

    context 'with subgroups' do
      let(:parent) { create(:group, name: 'parent', path: 'parent') }
      let(:child) { create(:group, name: 'child', path: 'child', parent: parent) }
      let!(:project) { create(:project_empty_repo, path: 'the-project', namespace: child) }
      let(:uploads_dir) { File.join(CarrierWave.root, FileUploader.base_dir) }
      let(:pages_dir) { File.join(TestEnv.pages_path) }

      before do
        FileUtils.mkdir_p(File.join(uploads_dir, 'parent', 'child', 'the-project'))
        FileUtils.mkdir_p(File.join(pages_dir, 'parent', 'child', 'the-project'))
      end

      context 'renaming child' do
        it 'correctly moves the repository, uploads and pages' do
          expected_repository_path = File.join(TestEnv.repos_path, 'parent', 'renamed', 'the-project.git')
          expected_upload_path = File.join(uploads_dir, 'parent', 'renamed', 'the-project')
          expected_pages_path = File.join(pages_dir, 'parent', 'renamed', 'the-project')

          child.update_attributes!(path: 'renamed')

          expect(File.directory?(expected_repository_path)).to be(true)
          expect(File.directory?(expected_upload_path)).to be(true)
          expect(File.directory?(expected_pages_path)).to be(true)
        end
      end

      context 'renaming parent' do
        it 'correctly moves the repository, uploads and pages' do
          expected_repository_path = File.join(TestEnv.repos_path, 'renamed', 'child', 'the-project.git')
          expected_upload_path = File.join(uploads_dir, 'renamed', 'child', 'the-project')
          expected_pages_path = File.join(pages_dir, 'renamed', 'child', 'the-project')

          parent.update_attributes!(path: 'renamed')

          expect(File.directory?(expected_repository_path)).to be(true)
          expect(File.directory?(expected_upload_path)).to be(true)
          expect(File.directory?(expected_pages_path)).to be(true)
        end
      end
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
    let!(:project) { create(:project_empty_repo, namespace: namespace) }
    let(:repository_storage_path) { Gitlab.config.repositories.storages.default['path'] }
    let(:path_in_dir) { File.join(repository_storage_path, namespace.full_path) }
    let(:deleted_path) { namespace.full_path.gsub(namespace.path, "#{namespace.full_path}+#{namespace.id}+deleted") }
    let(:deleted_path_in_dir) { File.join(repository_storage_path, deleted_path) }

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
      let!(:project) { create(:project_empty_repo, namespace: child) }
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

  describe '#soft_delete_without_removing_associations' do
    let(:project1) { create(:project_empty_repo, namespace: namespace) }

    it 'updates the deleted_at timestamp but preserves projects' do
      namespace.soft_delete_without_removing_associations

      expect(Project.all).to include(project1)
      expect(namespace.deleted_at).not_to be_nil
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

    it { expect(group.all_projects.to_a).to eq([project2, project1]) }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace do
  include ProjectForksHelper
  include GitHelpers
  include ReloadHelpers

  let!(:namespace) { create(:namespace, :with_namespace_settings) }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:repository_storage) { 'default' }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :project_statistics }
    it { is_expected.to belong_to :parent }
    it { is_expected.to have_many :children }
    it { is_expected.to have_one :root_storage_statistics }
    it { is_expected.to have_one :aggregation_schedule }
    it { is_expected.to have_one :namespace_settings }
    it { is_expected.to have_many :custom_emoji }
    it { is_expected.to have_one :package_setting_relation }
    it { is_expected.to have_one :onboarding_progress }
    it { is_expected.to have_one :admin_note }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }

    context 'validating the parent of a namespace' do
      context 'when the namespace has no parent' do
        it 'allows a namespace to have no parent associated with it' do
          namespace = build(:namespace)

          expect(namespace).to be_valid
        end
      end

      context 'when the namespace has a parent' do
        it 'does not allow a namespace to have a group as its parent' do
          namespace = build(:namespace, parent: build(:group))

          expect(namespace).not_to be_valid
          expect(namespace.errors[:parent_id].first).to eq('a user namespace cannot have a parent')
        end

        it 'does not allow a namespace to have another namespace as its parent' do
          namespace = build(:namespace, parent: build(:namespace))

          expect(namespace).not_to be_valid
          expect(namespace.errors[:parent_id].first).to eq('a user namespace cannot have a parent')
        end
      end

      context 'when the feature flag `validate_namespace_parent_type` is disabled' do
        before do
          stub_feature_flags(validate_namespace_parent_type: false)
        end

        context 'when the namespace has no parent' do
          it 'allows a namespace to have no parent associated with it' do
            namespace = build(:namespace)

            expect(namespace).to be_valid
          end
        end

        context 'when the namespace has a parent' do
          it 'allows a namespace to have a group as its parent' do
            namespace = build(:namespace, parent: build(:group))

            expect(namespace).to be_valid
          end

          it 'allows a namespace to have another namespace as its parent' do
            namespace = build(:namespace, parent: build(:namespace))

            expect(namespace).to be_valid
          end
        end
      end
    end

    it 'does not allow too deep nesting' do
      ancestors = (1..21).to_a
      group = build(:group)

      allow(group).to receive(:ancestors).and_return(ancestors)

      expect(group).not_to be_valid
      expect(group.errors[:parent_id].first).to eq('has too deep level of nesting')
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

    describe '1 char path length' do
      it 'does not allow to create one' do
        namespace = build(:namespace, path: 'j')

        expect(namespace).not_to be_valid
        expect(namespace.errors[:path].first).to eq('is too short (minimum is 2 characters)')
      end

      it 'does not allow to update one' do
        namespace = create(:namespace)
        namespace.update(path: 'j')

        expect(namespace).not_to be_valid
        expect(namespace.errors[:path].first).to eq('is too short (minimum is 2 characters)')
      end

      it 'allows updating other attributes for existing record' do
        namespace = build(:namespace, path: 'j', owner: create(:user))
        namespace.save(validate: false)
        namespace.reload

        expect(namespace.path).to eq('j')

        namespace.update(name: 'something new')

        expect(namespace).to be_valid
        expect(namespace.name).to eq('something new')
      end
    end
  end

  describe 'scopes', :aggregate_failures do
    let_it_be(:namespace1) { create(:group, name: 'Namespace 1', path: 'namespace-1') }
    let_it_be(:namespace2) { create(:group, name: 'Namespace 2', path: 'namespace-2') }
    let_it_be(:namespace1sub) { create(:group, name: 'Sub Namespace', path: 'sub-namespace', parent: namespace1) }
    let_it_be(:namespace2sub) { create(:group, name: 'Sub Namespace', path: 'sub-namespace', parent: namespace2) }

    describe '.by_parent' do
      it 'includes correct namespaces' do
        expect(described_class.by_parent(namespace1.id)).to eq([namespace1sub])
        expect(described_class.by_parent(namespace2.id)).to eq([namespace2sub])
        expect(described_class.by_parent(nil)).to match_array([namespace, namespace1, namespace2])
      end
    end

    describe '.filter_by_path' do
      it 'includes correct namespaces' do
        expect(described_class.filter_by_path(namespace1.path)).to eq([namespace1])
        expect(described_class.filter_by_path(namespace2.path)).to eq([namespace2])
        expect(described_class.filter_by_path('sub-namespace')).to match_array([namespace1sub, namespace2sub])
      end

      it 'filters case-insensitive' do
        expect(described_class.filter_by_path(namespace1.path.upcase)).to eq([namespace1])
      end
    end

    describe '.sorted_by_similarity_and_parent_id_desc' do
      it 'returns exact matches and top level groups first' do
        expect(described_class.sorted_by_similarity_and_parent_id_desc(namespace1.path)).to eq([namespace1, namespace2, namespace2sub, namespace1sub, namespace])
        expect(described_class.sorted_by_similarity_and_parent_id_desc(namespace2.path)).to eq([namespace2, namespace1, namespace2sub, namespace1sub, namespace])
        expect(described_class.sorted_by_similarity_and_parent_id_desc(namespace2sub.name)).to eq([namespace2sub, namespace1sub, namespace2, namespace1, namespace])
        expect(described_class.sorted_by_similarity_and_parent_id_desc('Namespace')).to eq([namespace2, namespace1, namespace2sub, namespace1sub, namespace])
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
    it { is_expected.to include_module(Namespaces::Traversal::Recursive) }
    it { is_expected.to include_module(Namespaces::Traversal::Linear) }
  end

  it_behaves_like 'linear namespace traversal'

  context 'traversal_ids on create' do
    context 'default traversal_ids' do
      let(:namespace) { build(:namespace) }

      before do
        namespace.save!
        namespace.reload
      end

      it { expect(namespace.traversal_ids).to eq [namespace.id] }
    end
  end

  describe "after_commit :expire_child_caches" do
    let(:namespace) { create(:group) }

    it "expires the child caches when updated" do
      child_1 = create(:group, parent: namespace, updated_at: 1.week.ago)
      child_2 = create(:group, parent: namespace, updated_at: 1.day.ago)
      grandchild = create(:group, parent: child_1, updated_at: 1.week.ago)
      project_1 = create(:project, namespace: namespace, updated_at: 2.days.ago)
      project_2 = create(:project, namespace: child_1, updated_at: 3.days.ago)
      project_3 = create(:project, namespace: grandchild, updated_at: 4.years.ago)

      freeze_time do
        namespace.update!(path: "foo")

        [namespace, child_1, child_2, grandchild, project_1, project_2, project_3].each do |record|
          expect(record.reload.updated_at).to eq(Time.zone.now)
        end
      end
    end

    it "expires on name changes" do
      expect(namespace).to receive(:expire_child_caches).once

      namespace.update!(name: "Foo")
    end

    it "expires on path changes" do
      expect(namespace).to receive(:expire_child_caches).once

      namespace.update!(path: "bar")
    end

    it "expires on parent changes" do
      expect(namespace).to receive(:expire_child_caches).once

      namespace.update!(parent: create(:group))
    end

    it "doesn't expire on other field changes" do
      expect(namespace).not_to receive(:expire_child_caches)

      namespace.update!(
        description: "Foo bar",
        max_artifacts_size: 10
      )
    end
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

  describe '#any_project_has_container_registry_tags?' do
    subject { namespace.any_project_has_container_registry_tags? }

    let!(:project_without_registry) { create(:project, namespace: namespace) }

    context 'without tags' do
      it { is_expected.to be_falsey }
    end

    context 'with tags' do
      before do
        repositories = create_list(:container_repository, 3)
        create(:project, namespace: namespace, container_repositories: repositories)

        stub_container_registry_config(enabled: true)
      end

      it 'finds tags' do
        stub_container_registry_tags(repository: :any, tags: ['tag'])

        is_expected.to be_truthy
      end

      it 'does not cause N+1 query in fetching registries' do
        stub_container_registry_tags(repository: :any, tags: [])
        control_count = ActiveRecord::QueryRecorder.new { namespace.any_project_has_container_registry_tags? }.count

        other_repositories = create_list(:container_repository, 2)
        create(:project, namespace: namespace, container_repositories: other_repositories)

        expect { namespace.any_project_has_container_registry_tags? }.not_to exceed_query_limit(control_count + 1)
      end
    end
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
    let_it_be(:first_group) { build(:group, name: 'my first namespace', path: 'old-path').tap(&:save!) }
    let_it_be(:parent_group) { build(:group, name: 'my parent namespace', path: 'parent-path').tap(&:save!) }
    let_it_be(:second_group) { build(:group, name: 'my second namespace', path: 'new-path', parent: parent_group).tap(&:save!) }
    let_it_be(:project_with_same_path) { create(:project, id: second_group.id, path: first_group.path) }

    it 'returns namespaces with a matching name' do
      expect(described_class.search('my first namespace')).to eq([first_group])
    end

    it 'returns namespaces with a partially matching name' do
      expect(described_class.search('first')).to eq([first_group])
    end

    it 'returns namespaces with a matching name regardless of the casing' do
      expect(described_class.search('MY FIRST NAMESPACE')).to eq([first_group])
    end

    it 'returns namespaces with a matching path' do
      expect(described_class.search('old-path')).to eq([first_group])
    end

    it 'returns namespaces with a partially matching path' do
      expect(described_class.search('old')).to eq([first_group])
    end

    it 'returns namespaces with a matching path regardless of the casing' do
      expect(described_class.search('OLD-PATH')).to eq([first_group])
    end

    it 'returns namespaces with a matching route path' do
      expect(described_class.search('parent-path/new-path', include_parents: true)).to eq([second_group])
    end

    it 'returns namespaces with a partially matching route path' do
      expect(described_class.search('parent-path/new', include_parents: true)).to eq([second_group])
    end

    it 'returns namespaces with a matching route path regardless of the casing' do
      expect(described_class.search('PARENT-PATH/NEW-PATH', include_parents: true)).to eq([second_group])
    end
  end

  describe '.with_statistics' do
    let_it_be(:namespace) { create(:namespace) }

    let(:project1) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               namespace:            namespace,
                               repository_size:      101,
                               wiki_size:            505,
                               lfs_objects_size:     202,
                               build_artifacts_size: 303,
                               packages_size:        404,
                               snippets_size:        605))
    end

    let(:project2) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               namespace:            namespace,
                               repository_size:      10,
                               wiki_size:            50,
                               lfs_objects_size:     20,
                               build_artifacts_size: 30,
                               packages_size:        40,
                               snippets_size:        60))
    end

    it "sums all project storage counters in the namespace" do
      project1
      project2
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 2330
      expect(statistics.repository_size).to eq 111
      expect(statistics.wiki_size).to eq 555
      expect(statistics.lfs_objects_size).to eq 222
      expect(statistics.build_artifacts_size).to eq 333
      expect(statistics.packages_size).to eq 444
      expect(statistics.snippets_size).to eq 665
    end

    it "correctly handles namespaces without projects" do
      statistics = described_class.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 0
      expect(statistics.repository_size).to eq 0
      expect(statistics.wiki_size).to eq 0
      expect(statistics.lfs_objects_size).to eq 0
      expect(statistics.build_artifacts_size).to eq 0
      expect(statistics.packages_size).to eq 0
      expect(statistics.snippets_size).to eq 0
    end
  end

  describe '.find_by_pages_host' do
    it 'finds namespace by GitLab Pages host and is case-insensitive' do
      namespace = create(:namespace, name: 'topNAMEspace', path: 'topNAMEspace')
      create(:namespace, name: 'annother_namespace')
      host = "TopNamespace.#{Settings.pages.host.upcase}"

      expect(described_class.find_by_pages_host(host)).to eq(namespace)
    end

    context 'when there is non-top-level group with searched name' do
      before do
        create(:group, :nested, path: 'pages')
      end

      it 'ignores this group' do
        host = "pages.#{Settings.pages.host.upcase}"

        expect(described_class.find_by_pages_host(host)).to be_nil
      end

      it 'finds right top level group' do
        group = create(:group, path: 'pages')

        host = "pages.#{Settings.pages.host.upcase}"

        expect(described_class.find_by_pages_host(host)).to eq(group)
      end
    end

    it "returns no result if the provided host is not subdomain of the Pages host" do
      create(:namespace, name: 'namespace.io')
      host = "namespace.io"

      expect(described_class.find_by_pages_host(host)).to eq(nil)
    end
  end

  describe '.top_most' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }

    subject { described_class.top_most.ids }

    it 'only contains root namespaces' do
      is_expected.to contain_exactly(group.id, namespace.id)
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

        def expect_project_directories_at(namespace_path, with_pages: true)
          expected_repository_path = File.join(TestEnv.repos_path, namespace_path, 'the-project.git')
          expected_upload_path = File.join(uploads_dir, namespace_path, 'the-project')
          expected_pages_path = File.join(pages_dir, namespace_path, 'the-project')

          expect(File.directory?(expected_repository_path)).to be_truthy
          expect(File.directory?(expected_upload_path)).to be_truthy
          expect(File.directory?(expected_pages_path)).to be(with_pages)
        end

        before do
          FileUtils.mkdir_p(File.join(TestEnv.repos_path, "#{project.full_path}.git"))
          FileUtils.mkdir_p(File.join(uploads_dir, project.full_path))
          FileUtils.mkdir_p(File.join(pages_dir, project.full_path))
        end

        after do
          FileUtils.remove_entry(File.join(TestEnv.repos_path, parent.full_path), true)
          FileUtils.remove_entry(File.join(TestEnv.repos_path, new_parent.full_path), true)
          FileUtils.remove_entry(File.join(TestEnv.repos_path, child.full_path), true)
          FileUtils.remove_entry(File.join(uploads_dir, project.full_path), true)
          FileUtils.remove_entry(pages_dir, true)
        end

        context 'renaming child' do
          context 'when no projects have pages deployed' do
            it 'moves the repository and uploads', :sidekiq_inline do
              project.pages_metadatum.update!(deployed: false)
              child.update!(path: 'renamed')

              expect_project_directories_at('parent/renamed', with_pages: false)
            end
          end

          context 'when the project has pages deployed' do
            before do
              project.pages_metadatum.update!(deployed: true)
            end

            it 'correctly moves the repository, uploads and pages', :sidekiq_inline do
              child.update!(path: 'renamed')

              expect_project_directories_at('parent/renamed')
            end

            it 'performs the move async of pages async' do
              expect(PagesTransferWorker).to receive(:perform_async).with('rename_namespace', ['parent/child', 'parent/renamed'])

              child.update!(path: 'renamed')
            end
          end
        end

        context 'renaming parent' do
          context 'when no projects have pages deployed' do
            it 'moves the repository and uploads', :sidekiq_inline do
              project.pages_metadatum.update!(deployed: false)
              parent.update!(path: 'renamed')

              expect_project_directories_at('renamed/child', with_pages: false)
            end
          end

          context 'when the project has pages deployed' do
            before do
              project.pages_metadatum.update!(deployed: true)
            end

            it 'correctly moves the repository, uploads and pages', :sidekiq_inline do
              parent.update!(path: 'renamed')

              expect_project_directories_at('renamed/child')
            end

            it 'performs the move async of pages async' do
              expect(PagesTransferWorker).to receive(:perform_async).with('rename_namespace', %w(parent renamed))

              parent.update!(path: 'renamed')
            end
          end
        end

        context 'moving from one parent to another' do
          context 'when no projects have pages deployed' do
            it 'moves the repository and uploads', :sidekiq_inline do
              project.pages_metadatum.update!(deployed: false)
              child.update!(parent: new_parent)

              expect_project_directories_at('new_parent/child', with_pages: false)
            end
          end

          context 'when the project has pages deployed' do
            before do
              project.pages_metadatum.update!(deployed: true)
            end

            it 'correctly moves the repository, uploads and pages', :sidekiq_inline do
              child.update!(parent: new_parent)

              expect_project_directories_at('new_parent/child')
            end

            it 'performs the move async of pages async' do
              expect(PagesTransferWorker).to receive(:perform_async).with('move_namespace', %w(child parent new_parent))

              child.update!(parent: new_parent)
            end
          end
        end

        context 'moving from having a parent to root' do
          context 'when no projects have pages deployed' do
            it 'moves the repository and uploads', :sidekiq_inline do
              project.pages_metadatum.update!(deployed: false)
              child.update!(parent: nil)

              expect_project_directories_at('child', with_pages: false)
            end
          end

          context 'when the project has pages deployed' do
            before do
              project.pages_metadatum.update!(deployed: true)
            end

            it 'correctly moves the repository, uploads and pages', :sidekiq_inline do
              child.update!(parent: nil)

              expect_project_directories_at('child')
            end

            it 'performs the move async of pages async' do
              expect(PagesTransferWorker).to receive(:perform_async).with('move_namespace', ['child', 'parent', nil])

              child.update!(parent: nil)
            end
          end
        end

        context 'moving from root to having a parent' do
          context 'when no projects have pages deployed' do
            it 'moves the repository and uploads', :sidekiq_inline do
              project.pages_metadatum.update!(deployed: false)
              parent.update!(parent: new_parent)

              expect_project_directories_at('new_parent/parent/child', with_pages: false)
            end
          end

          context 'when the project has pages deployed' do
            before do
              project.pages_metadatum.update!(deployed: true)
            end

            it 'correctly moves the repository, uploads and pages', :sidekiq_inline do
              parent.update!(parent: new_parent)

              expect_project_directories_at('new_parent/parent/child')
            end

            it 'performs the move async of pages async' do
              expect(PagesTransferWorker).to receive(:perform_async).with('move_namespace', ['parent', nil, 'new_parent'])

              parent.update!(parent: new_parent)
            end
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
        repository_project_in_parent_group = project_in_parent_group.project_repository
        repository_hashed_project_in_subgroup = hashed_project_in_subgroup.project_repository
        repository_legacy_project_in_subgroup = legacy_project_in_subgroup.project_repository

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
        expect(GitlabShellWorker).not_to receive(:perform_in)

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

  describe ".clean_name" do
    context "when the name complies with the group name regex" do
      it "returns the name as is" do
        valid_name = "Hello - World _ (Hi.)"
        expect(described_class.clean_name(valid_name)).to eq(valid_name)
      end
    end

    context "when the name does not comply with the group name regex" do
      it "sanitizes the name by replacing all invalid char sequences with a space" do
        expect(described_class.clean_name("Green'! Test~~~")).to eq("Green Test")
      end
    end
  end

  describe "#default_branch_protection" do
    let(:namespace) { create(:namespace) }
    let(:default_branch_protection) { nil }
    let(:group) { create(:group, default_branch_protection: default_branch_protection) }

    before do
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
    end

    context 'for a namespace' do
      # Unlike a group, the settings of a namespace cannot be altered
      # via the UI or the API.

      it 'returns the instance level setting' do
        expect(namespace.default_branch_protection).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
      end
    end

    context 'for a group' do
      context 'that has not altered the default value' do
        it 'returns the instance level setting' do
          expect(group.default_branch_protection).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
        end
      end

      context 'that has altered the default value' do
        let(:default_branch_protection) { Gitlab::Access::PROTECTION_FULL }

        it 'returns the group level setting' do
          expect(group.default_branch_protection).to eq(default_branch_protection)
        end
      end
    end
  end

  describe '#use_traversal_ids?' do
    let_it_be(:namespace, reload: true) { create(:namespace) }

    subject { namespace.use_traversal_ids? }

    context 'when use_traversal_ids feature flag is true' do
      before do
        stub_feature_flags(use_traversal_ids: true)
      end

      it { is_expected.to eq true }
    end

    context 'when use_traversal_ids feature flag is false' do
      before do
        stub_feature_flags(use_traversal_ids: false)
      end

      it { is_expected.to eq false }
    end
  end

  describe '#use_traversal_ids_for_ancestors?' do
    let_it_be(:namespace, reload: true) { create(:namespace) }

    subject { namespace.use_traversal_ids_for_ancestors? }

    context 'when use_traversal_ids_for_ancestors? feature flag is true' do
      before do
        stub_feature_flags(use_traversal_ids_for_ancestors: true)
      end

      it { is_expected.to eq true }
    end

    context 'when use_traversal_ids_for_ancestors? feature flag is false' do
      before do
        stub_feature_flags(use_traversal_ids_for_ancestors: false)
      end

      it { is_expected.to eq false }
    end

    context 'when use_traversal_ids? feature flag is false' do
      before do
        stub_feature_flags(use_traversal_ids: false)
      end

      it { is_expected.to eq false }
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

  shared_examples '#all_projects' do
    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group) }
      let_it_be(:child) { create(:group, parent: namespace) }
      let_it_be(:project1) { create(:project_empty_repo, namespace: namespace) }
      let_it_be(:project2) { create(:project_empty_repo, namespace: child) }
      let_it_be(:other_project) { create(:project_empty_repo) }

      before do
        reload_models(namespace, child)
      end

      it { expect(namespace.all_projects.to_a).to match_array([project2, project1]) }
      it { expect(child.all_projects.to_a).to match_array([project2]) }
    end

    context 'when namespace is a user namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_namespace) { create(:namespace, owner: user) }
      let_it_be(:project) { create(:project, namespace: user_namespace) }
      let_it_be(:other_project) { create(:project_empty_repo) }

      before do
        reload_models(user_namespace)
      end

      it { expect(user_namespace.all_projects.to_a).to match_array([project]) }
    end
  end

  describe '#all_projects' do
    context 'when recursive approach is disabled' do
      before do
        stub_feature_flags(recursive_approach_for_all_projects: false)
      end

      include_examples '#all_projects'
    end

    context 'with use_traversal_ids feature flag enabled' do
      before do
        stub_feature_flags(use_traversal_ids: true)
      end

      include_examples '#all_projects'

      # Using #self_and_descendant instead of #self_and_descendant_ids can produce
      # very slow queries.
      it 'calls self_and_descendant_ids' do
        namespace = create(:group)
        expect(namespace).to receive(:self_and_descendant_ids)
        namespace.all_projects
      end
    end

    context 'with use_traversal_ids feature flag disabled' do
      before do
        stub_feature_flags(use_traversal_ids: false)
      end

      include_examples '#all_projects'
    end
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
    context 'with persisted root group' do
      let!(:root_group) { create(:group) }

      it 'returns root_ancestor for root group without a query' do
        expect { root_group.root_ancestor }.not_to exceed_query_limit(0)
      end

      it 'returns the top most ancestor' do
        nested_group = create(:group, parent: root_group)
        deep_nested_group = create(:group, parent: nested_group)
        very_deep_nested_group = create(:group, parent: deep_nested_group)

        expect(root_group.root_ancestor).to eq(root_group)
        expect(nested_group.root_ancestor).to eq(root_group)
        expect(deep_nested_group.root_ancestor).to eq(root_group)
        expect(very_deep_nested_group.root_ancestor).to eq(root_group)
      end
    end

    context 'with not persisted root group' do
      let!(:root_group) { build(:group) }

      it 'returns root_ancestor for root group without a query' do
        expect { root_group.root_ancestor }.not_to exceed_query_limit(0)
      end

      it 'returns the top most ancestor' do
        nested_group = build(:group, parent: root_group)
        deep_nested_group = build(:group, parent: nested_group)
        very_deep_nested_group = build(:group, parent: deep_nested_group)

        expect(root_group.root_ancestor).to eq(root_group)
        expect(nested_group.root_ancestor).to eq(root_group)
        expect(deep_nested_group.root_ancestor).to eq(root_group)
        expect(very_deep_nested_group.root_ancestor).to eq(root_group)
      end
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

      it 'does not query the db when there is no parent group' do
        group = create(:group, emails_disabled: true)

        expect { group.emails_disabled? }.not_to exceed_query_limit(0)
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

    it 'returns the virual domain' do
      project.mark_pages_as_deployed
      project.update_pages_deployment!(create(:pages_deployment, project: project))

      virtual_domain = namespace.pages_virtual_domain

      expect(virtual_domain).to be_an_instance_of(Pages::VirtualDomain)
      expect(virtual_domain.lookup_paths).not_to be_empty
    end
  end

  describe '#any_project_with_pages_deployed?' do
    it 'returns true if any project nested under the group has pages deployed' do
      parent_1 = create(:group) # Three projects, one with pages
      child_1_1 = create(:group, parent: parent_1) # Two projects, one with pages
      child_1_2 = create(:group, parent: parent_1) # One project, no pages
      parent_2 = create(:group) # No projects

      create(:project, group: child_1_1).tap do |project|
        project.pages_metadatum.update!(deployed: true)
      end

      create(:project, group: child_1_1)
      create(:project, group: child_1_2)

      expect(parent_1.any_project_with_pages_deployed?).to be(true)
      expect(child_1_1.any_project_with_pages_deployed?).to be(true)
      expect(child_1_2.any_project_with_pages_deployed?).to be(false)
      expect(parent_2.any_project_with_pages_deployed?).to be(false)
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
      let!(:parent) { create(:group) }
      let!(:group) { create(:group, parent: parent) }

      let(:setting) { group.closest_setting(setting_name) }

      before do
        parent.update_attribute(setting_name, root_setting)
        group.update_attribute(setting_name, child_setting)
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

  describe '#paid?' do
    it 'returns false for a root namespace with a free plan' do
      expect(namespace.paid?).to eq(false)
    end
  end

  describe '#shared_runners_setting' do
    using RSpec::Parameterized::TableSyntax

    where(:shared_runners_enabled, :allow_descendants_override_disabled_shared_runners, :shared_runners_setting) do
      true  | true  | 'enabled'
      true  | false | 'enabled'
      false | true  | 'disabled_with_override'
      false | false | 'disabled_and_unoverridable'
    end

    with_them do
      let(:namespace) { build(:namespace, shared_runners_enabled: shared_runners_enabled, allow_descendants_override_disabled_shared_runners: allow_descendants_override_disabled_shared_runners)}

      it 'returns the result' do
        expect(namespace.shared_runners_setting).to eq(shared_runners_setting)
      end
    end
  end

  describe '#shared_runners_setting_higher_than?' do
    using RSpec::Parameterized::TableSyntax

    where(:shared_runners_enabled, :allow_descendants_override_disabled_shared_runners, :other_setting, :result) do
      true  | true  | 'enabled'                    | false
      true  | true  | 'disabled_with_override'     | true
      true  | true  | 'disabled_and_unoverridable' | true
      false | true  | 'enabled'                    | false
      false | true  | 'disabled_with_override'     | false
      false | true  | 'disabled_and_unoverridable' | true
      false | false | 'enabled'                    | false
      false | false | 'disabled_with_override'     | false
      false | false | 'disabled_and_unoverridable' | false
    end

    with_them do
      let(:namespace) { build(:namespace, shared_runners_enabled: shared_runners_enabled, allow_descendants_override_disabled_shared_runners: allow_descendants_override_disabled_shared_runners)}

      it 'returns the result' do
        expect(namespace.shared_runners_setting_higher_than?(other_setting)).to eq(result)
      end
    end
  end

  describe 'validation #changing_shared_runners_enabled_is_allowed' do
    context 'without a parent' do
      let(:namespace) { build(:namespace, shared_runners_enabled: true) }

      it 'is valid' do
        expect(namespace).to be_valid
      end
    end

    context 'with a parent' do
      context 'when parent has shared runners disabled' do
        let(:parent) { create(:group, :shared_runners_disabled) }
        let(:group) { build(:group, shared_runners_enabled: true, parent_id: parent.id) }

        it 'is invalid' do
          expect(group).to be_invalid
          expect(group.errors[:shared_runners_enabled]).to include('cannot be enabled because parent group has shared Runners disabled')
        end
      end

      context 'when parent has shared runners disabled but allows override' do
        let(:parent) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners) }
        let(:group) { build(:group, shared_runners_enabled: true, parent_id: parent.id) }

        it 'is valid' do
          expect(group).to be_valid
        end
      end

      context 'when parent has shared runners enabled' do
        let(:parent) { create(:group, shared_runners_enabled: true) }
        let(:group) { build(:group, shared_runners_enabled: true, parent_id: parent.id) }

        it 'is valid' do
          expect(group).to be_valid
        end
      end
    end
  end

  describe 'validation #changing_allow_descendants_override_disabled_shared_runners_is_allowed' do
    context 'without a parent' do
      context 'with shared runners disabled' do
        let(:namespace) { build(:namespace, :allow_descendants_override_disabled_shared_runners, :shared_runners_disabled) }

        it 'is valid' do
          expect(namespace).to be_valid
        end
      end

      context 'with shared runners enabled' do
        let(:namespace) { create(:namespace) }

        it 'is invalid' do
          namespace.allow_descendants_override_disabled_shared_runners = true

          expect(namespace).to be_invalid
          expect(namespace.errors[:allow_descendants_override_disabled_shared_runners]).to include('cannot be changed if shared runners are enabled')
        end
      end
    end

    context 'with a parent' do
      context 'when parent does not allow shared runners' do
        let(:parent) { create(:group, :shared_runners_disabled) }
        let(:group) { build(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners, parent_id: parent.id) }

        it 'is invalid' do
          expect(group).to be_invalid
          expect(group.errors[:allow_descendants_override_disabled_shared_runners]).to include('cannot be enabled because parent group does not allow it')
        end
      end

      context 'when parent allows shared runners and setting to true' do
        let(:parent) { create(:group, shared_runners_enabled: true) }
        let(:group) { build(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners, parent_id: parent.id) }

        it 'is valid' do
          expect(group).to be_valid
        end
      end

      context 'when parent allows shared runners and setting to false' do
        let(:parent) { create(:group, shared_runners_enabled: true) }
        let(:group) { build(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent_id: parent.id) }

        it 'is valid' do
          expect(group).to be_valid
        end
      end
    end
  end

  describe '#root?' do
    subject { namespace.root? }

    context 'when is subgroup' do
      before do
        namespace.parent = build(:group)
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when is root' do
      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end

  describe '#recent?' do
    subject { namespace.recent? }

    context 'when created more than 90 days ago' do
      before do
        namespace.update_attribute(:created_at, 91.days.ago)
      end

      it { is_expected.to be(false) }
    end

    context 'when created less than 90 days ago' do
      before do
        namespace.update_attribute(:created_at, 89.days.ago)
      end

      it { is_expected.to be(true) }
    end
  end
end

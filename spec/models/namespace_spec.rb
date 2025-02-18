# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace, feature_category: :groups_and_projects do
  include ContainerRegistryHelpers
  include ProjectForksHelper
  include ReloadHelpers

  let_it_be(:group_sti_name) { Group.sti_name }
  let_it_be(:project_sti_name) { Namespaces::ProjectNamespace.sti_name }
  let_it_be(:user_sti_name) { Namespaces::UserNamespace.sti_name }

  let_it_be(:organization) { create(:organization) }
  let!(:namespace) { create(:namespace, :with_namespace_settings) }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:repository_storage) { 'default' }

  describe 'associations' do
    it { is_expected.to belong_to :organization }
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :project_statistics }
    it { is_expected.to belong_to :parent }
    it { is_expected.to have_many :children }
    it { is_expected.to have_one :root_storage_statistics }
    it { is_expected.to have_one :aggregation_schedule }
    it { is_expected.to have_one :namespace_settings }
    it { is_expected.to have_one :namespace_details }
    it { is_expected.to have_one(:namespace_statistics) }
    it { is_expected.to have_one(:catalog_verified_namespace) }
    it { is_expected.to have_many :custom_emoji }
    it { is_expected.to have_one :package_setting_relation }
    it { is_expected.to have_one :admin_note }
    it { is_expected.to have_many :pending_builds }
    it { is_expected.to have_one :namespace_route }
    it { is_expected.to have_many :namespace_members }
    it { is_expected.to have_one :cluster_enabled_grant }
    it { is_expected.to have_many(:work_items) }
    it { is_expected.to have_many(:work_items_dates_source) }
    it { is_expected.to have_many :achievements }
    it { is_expected.to have_many(:namespace_commit_emails).class_name('Users::NamespaceCommitEmail') }
    it { is_expected.to have_many(:cycle_analytics_stages) }
    it { is_expected.to have_many(:value_streams) }
    it { is_expected.to have_many(:non_archived_projects).class_name('Project') }
    it { is_expected.to have_many(:bot_users).through(:bot_user_details).source(:user) }

    it do
      is_expected.to have_many(:bot_user_details)
                       .class_name('UserDetail')
                       .with_foreign_key(:bot_namespace_id)
                       .inverse_of(:bot_namespace)
    end

    it do
      is_expected.to have_one(:ci_cd_settings).class_name('NamespaceCiCdSetting').inverse_of(:namespace).autosave(true)
    end

    describe '#children' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:project_with_namespace) { create(:project, namespace: group) }

      it 'excludes project namespaces' do
        expect(project_with_namespace.project_namespace.parent).to eq(group)
        expect(group.children).to match_array([subgroup])
      end
    end
  end

  shared_examples 'validations called by different namespace types' do |method|
    using RSpec::Parameterized::TableSyntax

    where(:namespace_type, :call_validation) do
      :namespace            | true
      :group                | true
      :user_namespace       | true
      :project_namespace    | false
    end

    with_them do
      it 'conditionally runs given validation' do
        namespace = build(namespace_type)
        if call_validation
          expect(namespace).to receive(method)
        else
          expect(namespace).not_to receive(method)
        end

        namespace.valid?
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }

    context 'validating the parent of a namespace' do
      using RSpec::Parameterized::TableSyntax

      where(:parent_type, :child_type, :error) do
        nil                      | ref(:user_sti_name)      | nil
        nil                      | ref(:group_sti_name)     | nil
        nil                      | ref(:project_sti_name)   | 'must be set for a project namespace'
        ref(:project_sti_name)   | ref(:user_sti_name)      | 'project namespace cannot be the parent of another namespace'
        ref(:project_sti_name)   | ref(:group_sti_name)     | 'project namespace cannot be the parent of another namespace'
        ref(:project_sti_name)   | ref(:project_sti_name)   | 'project namespace cannot be the parent of another namespace'
        ref(:group_sti_name)     | ref(:user_sti_name)      | 'cannot be used for user namespace'
        ref(:group_sti_name)     | ref(:group_sti_name)     | nil
        ref(:group_sti_name)     | ref(:project_sti_name)   | nil
        ref(:user_sti_name)      | ref(:user_sti_name)      | 'cannot be used for user namespace'
        ref(:user_sti_name)      | ref(:group_sti_name)     | 'user namespace cannot be the parent of another namespace'
        ref(:user_sti_name)      | ref(:project_sti_name)   | nil
      end

      with_them do
        it 'validates namespace parent' do
          parent = build(:namespace, type: parent_type) if parent_type
          namespace = build(:namespace, type: child_type, parent: parent)

          if error
            expect(namespace).not_to be_valid
            expect(namespace.errors[:parent_id].first).to eq(error)
          else
            expect(namespace).to be_valid
          end
        end
      end
    end

    describe '#nesting_level_allowed' do
      context 'for a group' do
        it 'does not allow too deep nesting' do
          ancestors = (1..21).to_a
          group = build(:group)

          allow(group).to receive(:ancestors).and_return(ancestors)

          expect(group).not_to be_valid
          expect(group.errors[:parent_id].first).to eq('has too deep level of nesting')
        end
      end

      it_behaves_like 'validations called by different namespace types', :nesting_level_allowed
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
        let(:group) { build(:namespace, path: 'tree') }

        it { expect(group).to be_valid }
      end
    end

    describe 'path validator' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:parent) { create(:namespace) }

      where(:namespace_type, :path, :valid) do
        ref(:project_sti_name)   | 'j'               | true
        ref(:project_sti_name)   | 'path.'           | false
        ref(:project_sti_name)   | '.path'           | false
        ref(:project_sti_name)   | 'path.git'        | false
        ref(:project_sti_name)   | 'namespace__path' | false
        ref(:project_sti_name)   | 'blob'            | false
        ref(:group_sti_name)     | 'j'               | false
        ref(:group_sti_name)     | 'path.'           | false
        ref(:group_sti_name)     | '.path'           | false
        ref(:group_sti_name)     | 'path.git'        | false
        ref(:group_sti_name)     | 'namespace__path' | false
        ref(:group_sti_name)     | 'blob'            | true
        ref(:user_sti_name)      | 'j'               | false
        ref(:user_sti_name)      | 'path.'           | false
        ref(:user_sti_name)      | '.path'           | false
        ref(:user_sti_name)      | 'path.git'        | false
        ref(:user_sti_name)      | 'namespace__path' | false
        ref(:user_sti_name)      | 'blob'            | true
      end

      with_them do
        it 'validates namespace path' do
          parent_namespace = parent if namespace_type == Namespaces::ProjectNamespace.sti_name
          namespace = build(:namespace, type: namespace_type, parent: parent_namespace, path: path)

          expect(namespace.valid?).to be(valid)
        end
      end

      context 'when path starts or ends with a special character' do
        it 'does not raise validation error for path for existing namespaces' do
          parent.update_attribute(:path, '_path_')

          expect { parent.update!(name: 'Foo') }.not_to raise_error
        end
      end
    end

    describe '1 char path length' do
      context 'with user namespace' do
        let(:namespace) { build(:namespace) }

        it 'does not allow to update path to single char' do
          namespace.save!

          namespace.path = 'j'

          expect(namespace).not_to be_valid
          expect(namespace.errors[:path].first).to eq('is too short (minimum is 2 characters)')
        end

        it 'allows updating other attributes for existing record' do
          namespace.save!
          namespace.update_attribute(:path, 'j')
          namespace.reload

          expect(namespace.path).to eq('j')

          namespace.update!(name: 'something new')

          expect(namespace).to be_valid
          expect(namespace.name).to eq('something new')
        end
      end

      context 'with project namespace' do
        let(:namespace) { build(:project_namespace) }

        it 'allows to update path to single char' do
          project = create(:project)
          namespace = project.project_namespace

          namespace.update!(path: 'j')

          expect(namespace).to be_valid
        end
      end
    end

    describe '#parent_organization_match' do
      let_it_be(:group) { create(:group, :with_organization) }

      subject(:namespace) { build(:group, parent: group, organization: organization) }

      context "when namespace belongs to parent's organization" do
        let(:organization) { group.organization }

        it { is_expected.to be_valid }
      end

      context "when namespace does not belong to parent's organization" do
        let(:organization) { build(:organization) }

        it 'is not valid and adds an error message' do
          expect(namespace).not_to be_valid
          expect(namespace.errors[:organization_id]).to include("must match the parent organization's ID")
        end
      end
    end
  end

  describe "ReferencePatternValidation" do
    subject { described_class.reference_pattern }

    it { is_expected.to match("@group1") }
    it { is_expected.to match("@group1/group2/group3") }
    it { is_expected.to match("@1234/1234/1234") }
    it { is_expected.to match("@.q-w_e") }
  end

  describe '#to_reference_base' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:user_namespace) { user.namespace }

    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:another_group) { create(:group) }

    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:project_namespace) { project.project_namespace }

    let_it_be(:another_namespace_project) { create(:project) }
    let_it_be(:another_namespace_project_namespace) { another_namespace_project.project_namespace }

    context 'when absolute_path is true' do
      it 'returns complete path to the project with leading slash', :aggregate_failures do
        be_full_path = eq("/#{parent.full_path}")

        expect(parent.to_reference_base(full: true, absolute_path: true)).to be_full_path
      end
    end

    # testing references with namespace being: group, project namespace and user namespace
    where(:namespace, :full, :from, :result) do
      ref(:parent)             | false | nil                                       | nil
      ref(:parent)             | true  | nil                                       | lazy { parent.full_path }
      ref(:parent)             | false | ref(:group)                               | lazy { parent.path }
      ref(:parent)             | true  | ref(:group)                               | lazy { parent.full_path }
      ref(:parent)             | false | ref(:parent)                              | nil
      ref(:parent)             | true  | ref(:parent)                              | lazy { parent.full_path }
      ref(:parent)             | false | ref(:project)                             | lazy { parent.path }
      ref(:parent)             | true  | ref(:project)                             | lazy { parent.full_path }
      ref(:parent)             | false | ref(:project_namespace)                   | lazy { parent.path }
      ref(:parent)             | true  | ref(:project_namespace)                   | lazy { parent.full_path }
      ref(:parent)             | false | ref(:another_group)                       | lazy { parent.full_path }
      ref(:parent)             | true  | ref(:another_group)                       | lazy { parent.full_path }
      ref(:parent)             | false | ref(:another_namespace_project)           | lazy { parent.full_path }
      ref(:parent)             | true  | ref(:another_namespace_project)           | lazy { parent.full_path }
      ref(:parent)             | false | ref(:another_namespace_project_namespace) | lazy { parent.full_path }
      ref(:parent)             | true  | ref(:another_namespace_project_namespace) | lazy { parent.full_path }
      ref(:parent)             | false | ref(:user_namespace)                      | lazy { parent.full_path }
      ref(:parent)             | true  | ref(:user_namespace)                      | lazy { parent.full_path }

      ref(:group)             | false | nil                                       | nil
      ref(:group)             | true  | nil                                       | lazy { group.full_path }
      ref(:group)             | false | ref(:group)                               | nil
      ref(:group)             | true  | ref(:group)                               | lazy { group.full_path }
      ref(:group)             | false | ref(:parent)                              | lazy { group.full_path }
      ref(:group)             | true  | ref(:parent)                              | lazy { group.full_path }
      ref(:group)             | false | ref(:project)                             | lazy { group.path }
      ref(:group)             | true  | ref(:project)                             | lazy { group.full_path }
      ref(:group)             | false | ref(:project_namespace)                   | lazy { group.path }
      ref(:group)             | true  | ref(:project_namespace)                   | lazy { group.full_path }
      ref(:group)             | false | ref(:another_group)                       | lazy { group.full_path }
      ref(:group)             | true  | ref(:another_group)                       | lazy { group.full_path }
      ref(:group)             | false | ref(:another_namespace_project)           | lazy { group.full_path }
      ref(:group)             | true  | ref(:another_namespace_project)           | lazy { group.full_path }
      ref(:group)             | false | ref(:another_namespace_project_namespace) | lazy { group.full_path }
      ref(:group)             | true  | ref(:another_namespace_project_namespace) | lazy { group.full_path }
      ref(:group)             | false | ref(:user_namespace)                      | lazy { group.full_path }
      ref(:group)             | true  | ref(:user_namespace)                      | lazy { group.full_path }

      ref(:project_namespace) | false | nil                                       | nil
      ref(:project_namespace) | true  | nil                                       | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:group)                               | lazy { project_namespace.path }
      ref(:project_namespace) | true  | ref(:group)                               | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:parent)                              | lazy { project_namespace.full_path }
      ref(:project_namespace) | true  | ref(:parent)                              | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:project)                             | nil
      ref(:project_namespace) | true  | ref(:project)                             | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:project_namespace)                   | nil
      ref(:project_namespace) | true  | ref(:project_namespace)                   | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:another_group)                       | lazy { project_namespace.full_path }
      ref(:project_namespace) | true  | ref(:another_group)                       | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:another_namespace_project)           | lazy { project_namespace.full_path }
      ref(:project_namespace) | true  | ref(:another_namespace_project)           | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:another_namespace_project_namespace) | lazy { project_namespace.full_path }
      ref(:project_namespace) | true  | ref(:another_namespace_project_namespace) | lazy { project_namespace.full_path }
      ref(:project_namespace) | false | ref(:user_namespace)                      | lazy { project_namespace.full_path }
      ref(:project_namespace) | true  | ref(:user_namespace)                      | lazy { project_namespace.full_path }

      ref(:user_namespace)    | false | nil                                       | nil
      ref(:user_namespace)    | true  | nil                                       | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:user_namespace)                      | nil
      ref(:user_namespace)    | true  | ref(:user_namespace)                      | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:group)                               | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:group)                               | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:parent)                              | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:parent)                              | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:project)                             | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:project)                             | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:project_namespace)                   | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:project_namespace)                   | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:another_group)                       | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:another_group)                       | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:another_namespace_project)           | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:another_namespace_project)           | lazy { user_namespace.full_path }
      ref(:user_namespace)    | false | ref(:another_namespace_project_namespace) | lazy { user_namespace.full_path }
      ref(:user_namespace)    | true  | ref(:another_namespace_project_namespace) | lazy { user_namespace.full_path }
    end

    with_them do
      it 'returns correct path' do
        expect(namespace.to_reference_base(from, full: full)).to eq(result)
      end
    end
  end

  describe 'handling STI', :aggregate_failures do
    let(:namespace_type) { nil }
    let(:parent) { nil }
    let(:namespace) { described_class.find(create(:namespace, type: namespace_type, parent: parent).id) }

    context 'creating a Group' do
      let(:namespace_type) { group_sti_name }

      it 'is the correct type of namespace' do
        expect(namespace).to be_a(Group)
        expect(namespace.kind).to eq('group')
        expect(namespace.group_namespace?).to be_truthy
      end
    end

    context 'creating a ProjectNamespace' do
      let(:namespace_type) { project_sti_name }
      let(:parent) { create(:group) }

      it 'is the correct type of namespace' do
        expect(described_class.find(namespace.id)).to be_a(Namespaces::ProjectNamespace)
        expect(namespace.kind).to eq('project')
        expect(namespace.project_namespace?).to be_truthy
      end
    end

    context 'creating a UserNamespace' do
      let(:namespace_type) { user_sti_name }

      it 'is the correct type of namespace' do
        expect(described_class.find(namespace.id)).to be_a(Namespaces::UserNamespace)
        expect(namespace.kind).to eq('user')
        expect(namespace.user_namespace?).to be_truthy
      end
    end

    context 'unable to create a Namespace with nil type' do
      let(:namespace) { nil }
      let(:namespace_type) { nil }

      it 'raises ActiveRecord::NotNullViolation' do
        expect { create(:namespace, type: namespace_type, parent: parent) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    context 'creating an unknown Namespace type' do
      let(:namespace_type) { 'nonsense' }

      it 'creates a default Namespace' do
        expect(described_class.find(namespace.id)).to be_a(described_class)
        expect(namespace.kind).to eq('user')
        expect(namespace.user_namespace?).to be_truthy
      end
    end
  end

  describe 'scopes', :aggregate_failures do
    let_it_be(:namespace1) { create(:group, name: 'Namespace 1', path: 'namespace-1') }
    let_it_be(:namespace2) { create(:group, name: 'Namespace 2', path: 'namespace-2') }
    let_it_be(:namespace1sub) { create(:group, name: 'Sub Namespace', path: 'sub-namespace', parent: namespace1) }
    let_it_be(:namespace2sub) { create(:group, name: 'Sub Namespace', path: 'sub-namespace', parent: namespace2) }

    describe '.without_deleted' do
      before do
        namespace1.namespace_details.update!(deleted_at: Time.current)
      end

      it 'does not include namespace marked as deleted' do
        expect(described_class.without_deleted).to contain_exactly(namespace, namespace2, namespace1sub, namespace2sub)
      end
    end

    describe '.by_parent' do
      it 'includes correct namespaces' do
        expect(described_class.by_parent(namespace1.id)).to match_array([namespace1sub])
        expect(described_class.by_parent(namespace2.id)).to match_array([namespace2sub])
        expect(described_class.by_parent(nil)).to match_array([namespace, namespace1, namespace2])
      end
    end

    describe '.top_level' do
      it 'includes correct namespaces' do
        expect(described_class.top_level).to match_array([namespace, namespace1, namespace2])
      end
    end

    describe '.by_root_id' do
      it 'returns correct namespaces' do
        expect(described_class.by_root_id(namespace1.id)).to match_array([namespace1, namespace1sub])
        expect(described_class.by_root_id(namespace2.id)).to match_array([namespace2, namespace2sub])
        expect(described_class.by_root_id(namespace1sub.id)).to be_empty
        expect(described_class.by_root_id(nil)).to be_empty
      end
    end

    describe '.by_not_in_root_id' do
      it 'returns correct namespaces' do
        expect(described_class.by_not_in_root_id(namespace1.id)).to contain_exactly(namespace, namespace2, namespace2sub)
        expect(described_class.by_not_in_root_id(namespace2.id)).to contain_exactly(namespace, namespace1, namespace1sub)
        expect(described_class.by_not_in_root_id(namespace1sub.id)).to match_array(described_class.all)
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

    describe '.by_name' do
      it 'includes correct namespaces' do
        expect(described_class.by_name(namespace1.name)).to eq([namespace1])
        expect(described_class.by_name(namespace2.name.chop)).to match_array([namespace1, namespace2])
      end
    end

    describe '.ordered_by_name' do
      let!(:namespace) { create(:group, name: 'Beta') }

      it 'includes namespaces in order' do
        expect(described_class.ordered_by_name).to eq [namespace, namespace1, namespace2, namespace1sub, namespace2sub]
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

    describe '.group_namespaces' do
      let_it_be(:user_namespace) { create(:user_namespace) }
      let_it_be(:project) { create(:project) }
      let_it_be(:project_namespace) { project.project_namespace }
      let_it_be(:group_namespace) { create(:group) }

      it 'only returns group namespaces' do
        group_namespaces = described_class.group_namespaces
        expect(group_namespaces).to include(group_namespace)
        expect(group_namespaces).not_to include(project_namespace, user_namespace)
      end
    end

    describe '.project_namespaces' do
      let_it_be(:user_namespace) { create(:user_namespace) }
      let_it_be(:project) { create(:project) }
      let_it_be(:project_namespace) { project.project_namespace }
      let_it_be(:group_namespace) { create(:group) }

      it 'only returns project namespaces' do
        project_namespaces = described_class.project_namespaces
        expect(project_namespaces).to include(project_namespace)
        expect(project_namespaces).not_to include(group_namespace, user_namespace)
      end
    end

    describe '.without_project_namespaces' do
      let_it_be(:user_namespace) { create(:user_namespace) }
      let_it_be(:project) { create(:project) }
      let_it_be(:project_namespace) { project.project_namespace }

      it 'excludes project namespaces' do
        expect(project_namespace).not_to be_nil
        expect(project_namespace.parent).not_to be_nil
        expect(described_class.all).to include(project_namespace)
        expect(described_class.without_project_namespaces).to match_array([namespace, namespace1, namespace2, namespace1sub, namespace2sub, user_namespace, project_namespace.parent])
      end
    end

    describe '.with_shared_runners_enabled' do
      subject { described_class.with_shared_runners_enabled }

      context 'when shared runners are enabled for namespace' do
        let!(:namespace_inheriting_shared_runners) { create(:namespace, shared_runners_enabled: true) }

        it "returns a namespace inheriting shared runners" do
          is_expected.to include(namespace_inheriting_shared_runners)
        end
      end

      context 'when shared runners are disabled for namespace' do
        let!(:namespace_not_inheriting_shared_runners) { create(:namespace, shared_runners_enabled: false) }

        it "does not return a namespace not inheriting shared runners" do
          is_expected.not_to include(namespace_not_inheriting_shared_runners)
        end
      end
    end
  end

  describe 'delegate' do
    it { is_expected.to delegate_method(:name).to(:owner).with_prefix.allow_nil }
    it { is_expected.to delegate_method(:avatar_url).to(:owner).allow_nil }
    it { is_expected.to delegate_method(:prevent_sharing_groups_outside_hierarchy).to(:namespace_settings).allow_nil }
    it { is_expected.to delegate_method(:runner_registration_enabled).to(:namespace_settings) }
    it { is_expected.to delegate_method(:runner_registration_enabled?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:default_branch_protection_defaults).to(:namespace_settings) }
    it { is_expected.to delegate_method(:allow_runner_registration_token).to(:namespace_settings) }
    it { is_expected.to delegate_method(:maven_package_requests_forwarding).to(:package_settings) }
    it { is_expected.to delegate_method(:pypi_package_requests_forwarding).to(:package_settings) }
    it { is_expected.to delegate_method(:npm_package_requests_forwarding).to(:package_settings) }
    it { is_expected.to delegate_method(:math_rendering_limits_enabled).to(:namespace_settings) }
    it { is_expected.to delegate_method(:math_rendering_limits_enabled?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:lock_math_rendering_limits_enabled?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:add_creator).to(:namespace_details) }
    it { is_expected.to delegate_method(:deleted_at).to(:namespace_details) }
    it { is_expected.to delegate_method(:deleted_at=).to(:namespace_details).with_arguments(:args) }
    it { is_expected.to delegate_method(:resource_access_token_notify_inherited?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:resource_access_token_notify_inherited_locked?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:resource_access_token_notify_inherited_locked_by_ancestor?).to(:namespace_settings) }
    it { is_expected.to delegate_method(:resource_access_token_notify_inherited_locked_by_application_setting?).to(:namespace_settings) }

    it do
      is_expected.to delegate_method(:prevent_sharing_groups_outside_hierarchy=).to(:namespace_settings)
                       .with_arguments(:args).allow_nil
    end

    it do
      is_expected.to delegate_method(:runner_registration_enabled=).to(:namespace_settings)
                       .with_arguments(:args)
    end

    it do
      is_expected.to delegate_method(:allow_runner_registration_token=).to(:namespace_settings)
                       .with_arguments(:args)
    end

    describe '#allow_runner_registration_token?' do
      subject { namespace.allow_runner_registration_token? }

      context 'when namespace_settings is nil' do
        let_it_be(:namespace) { create(:namespace) }

        it { is_expected.to eq false }
      end

      context 'when namespace_settings is not nil' do
        let_it_be(:namespace) { create(:namespace, :with_namespace_settings) }

        it { is_expected.to eq true }

        context 'when namespace_settings.allow_runner_registration_token? is false' do
          before do
            namespace.allow_runner_registration_token = false
          end

          it { is_expected.to eq false }
        end

        context 'when namespace_settings.allow_runner_registration_token? is true' do
          before do
            namespace.allow_runner_registration_token = true
          end

          it { is_expected.to eq true }
        end
      end
    end

    describe '#default_branch_protection_defaults' do
      context 'when namespace_settings is nil' do
        before do
          allow(subject).to receive(:namespace_settings).and_return(nil)
        end

        it 'does not raise an error' do
          expect { subject.default_branch_protection_defaults }.not_to raise_error
        end

        it 'returns nil' do
          expect(subject.default_branch_protection_defaults).to be_nil
        end
      end
    end

    describe "#default_branch_protection_settings" do
      let(:default_branch_protection_defaults) { {} }
      let(:namespace_setting) { create(:namespace_settings, default_branch_protection_defaults: default_branch_protection_defaults) }
      let(:namespace) { create(:namespace, namespace_settings: namespace_setting) }
      let(:group) { create(:group, namespace_settings: namespace_setting) }

      before do
        stub_application_setting(default_branch_protection_defaults: Gitlab::Access::BranchProtection.protected_against_developer_pushes)
      end

      context 'for a namespace' do
        it 'returns the instance level setting' do
          expected_settings = Gitlab::Access::BranchProtection.protected_against_developer_pushes.deep_stringify_keys
          settings = namespace.default_branch_protection_settings.to_hash

          expect(settings).to eq(expected_settings)
        end
      end

      context 'for a user namespace' do
        let_it_be(:user_namespace) { create(:user_namespace) }

        it 'returns the instance level setting' do
          expected_settings = Gitlab::Access::BranchProtection.protected_against_developer_pushes.deep_stringify_keys
          settings = user_namespace.default_branch_protection_settings.to_hash

          expect(settings).to eq(expected_settings)
        end
      end

      context 'for a group' do
        context 'that has not altered the default value' do
          it 'returns the instance level setting' do
            expected_settings = Gitlab::Access::BranchProtection.protected_against_developer_pushes.deep_stringify_keys
            settings = group.default_branch_protection_settings.to_hash

            expect(settings).to eq(expected_settings)
          end
        end

        context 'that has altered the default value' do
          let(:default_branch_protection_defaults) { Gitlab::Access::BranchProtection.protected_fully.deep_stringify_keys }

          it 'returns the group level setting' do
            expected_settings = default_branch_protection_defaults
            settings = group.default_branch_protection_settings.to_hash

            expect(settings).to eq(expected_settings)
          end
        end
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
    it { is_expected.to include_module(Namespaces::Traversal::Recursive) }
    it { is_expected.to include_module(Namespaces::Traversal::Linear) }
    it { is_expected.to include_module(Namespaces::Traversal::RecursiveScopes) }
    it { is_expected.to include_module(Namespaces::Traversal::LinearScopes) }
  end

  describe '#traversal_ids' do
    let(:namespace) { build(:group) }

    context 'when namespace not persisted' do
      it 'returns []' do
        expect(namespace.traversal_ids).to eq []
      end
    end

    context 'when namespace just saved' do
      let(:namespace) { build(:group) }

      before do
        namespace.save!
      end

      it 'returns value that matches database' do
        expect(namespace.traversal_ids).to eq described_class.find(namespace.id).traversal_ids
      end
    end

    context 'when namespace loaded from database' do
      before do
        namespace.save!
        namespace.reload
      end

      it 'returns database value' do
        expect(namespace.traversal_ids).to eq described_class.find(namespace.id).traversal_ids
      end
    end

    context 'when parent is nil' do
      let(:namespace) { build(:group, parent: nil) }

      it 'returns []' do
        expect(namespace.traversal_ids).to eq []
      end
    end

    context 'when made a child group' do
      let!(:parent_namespace) { create(:group) }
      let!(:namespace) { create(:group, parent: parent_namespace) }

      it 'returns database value' do
        expect(namespace.traversal_ids).to eq [parent_namespace.id, namespace.id]
      end
    end

    context 'when root_ancestor changes' do
      let(:old_root) { create(:group, organization: organization) }
      let(:namespace) { create(:group, parent: old_root) }
      let(:new_root) { create(:group, organization: organization) }

      it 'resets root_ancestor memo' do
        expect(namespace.root_ancestor).to eq old_root

        namespace.update!(parent: new_root)

        expect(namespace.root_ancestor).to eq new_root
      end
    end

    context 'within a transaction' do
      # We would like traversal_ids to be defined within a transaction, but it's not possible yet.
      # This spec exists to assert that the behavior is known.
      it 'is not defined yet' do
        Namespace.transaction do
          group = create(:group)
          expect(group.traversal_ids).to be_empty
        end
      end
    end
  end

  context 'traversal scopes' do
    it_behaves_like 'namespace traversal scopes'

    shared_examples 'does not make recursive queries' do
      specify do
        expect { subject }.not_to make_queries_matching(/WITH RECURSIVE/)
      end
    end

    describe '.self_and_descendants' do
      let_it_be(:namespace) { create(:namespace) }

      subject { described_class.where(id: namespace).self_and_descendants.load }

      it_behaves_like 'does not make recursive queries'
    end

    describe '.self_and_descendant_ids' do
      let_it_be(:namespace) { create(:namespace) }

      subject { described_class.where(id: namespace).self_and_descendant_ids.load }

      it_behaves_like 'does not make recursive queries'
    end
  end

  context 'traversal_ids on create' do
    let(:parent) { create(:group) }
    let(:child) { create(:group, parent: parent) }

    it { expect(parent.traversal_ids).to eq [parent.id] }
    it { expect(child.traversal_ids).to eq [parent.id, child.id] }
    it { expect(parent.sync_events.count).to eq 1 }
    it { expect(child.sync_events.count).to eq 1 }
  end

  context 'traversal_ids on update' do
    let(:namespace1) { create(:group, organization: organization) }
    let(:namespace2) { create(:group, organization: organization) }

    context 'when parent_id is changed' do
      subject { namespace1.update!(parent: namespace2) }

      it 'sets the traversal_ids attribute' do
        expect { subject }.to change { namespace1.traversal_ids }.from([namespace1.id]).to([namespace2.id, namespace1.id])
      end
    end

    it 'creates a Namespaces::SyncEvent using triggers' do
      Namespaces::SyncEvent.delete_all

      expect { namespace1.update!(parent: namespace2) }.to change(namespace1.sync_events, :count).by(1)
    end

    it 'creates sync_events using database trigger on the table' do
      namespace1.save!
      namespace2.save!

      expect { Group.update_all(traversal_ids: [-1]) }.to change(Namespaces::SyncEvent, :count).by(2)
    end

    it 'does not create sync_events using database trigger on the table when only the parent_id has changed' do
      expect { Group.update_all(parent_id: -1) }.not_to change(Namespaces::SyncEvent, :count)
    end

    it 'triggers the callback sync_traversal_ids on the namespace' do
      allow(namespace1).to receive(:run_callbacks).and_call_original
      expect(namespace1).to receive(:run_callbacks).with(:sync_traversal_ids)
      namespace1.update!(parent: namespace2)
    end

    it 'calls schedule_sync_event_worker on the updated namespace' do
      expect(namespace1).to receive(:schedule_sync_event_worker)
      namespace1.update!(parent: namespace2)
    end
  end

  describe "after_commit :expire_child_caches" do
    let(:namespace) { create(:group, organization: organization) }

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

      new_parent = create(:group, organization: organization)
      namespace.update!(parent: new_parent)
    end

    it "doesn't expire on other field changes" do
      expect(namespace).not_to receive(:expire_child_caches)

      namespace.update!(
        description: "Foo bar",
        max_artifacts_size: 10
      )
    end
  end

  describe '#owner_required?' do
    specify { expect(build(:project_namespace).owner_required?).to be_falsey }
    specify { expect(build(:group).owner_required?).to be_falsey }
    specify { expect(build(:namespace).owner_required?).to be_truthy }
  end

  describe '#visibility_level_field' do
    it { expect(namespace.visibility_level_field).to eq(:visibility_level) }
  end

  describe '#to_param' do
    it { expect(namespace.to_param).to eq(namespace.full_path) }
  end

  describe '#human_name' do
    it { expect(namespace.human_name).to eq(namespace.owner_name) }

    context 'when the owner is missing' do
      before do
        namespace.update_column(:owner_id, non_existing_record_id)
      end

      it { expect(namespace.human_name).to eq(namespace.path) }
    end
  end

  describe '#any_project_has_container_registry_tags?' do
    subject { namespace.any_project_has_container_registry_tags? }

    let(:project) { create(:project, namespace: namespace) }

    it 'returns true if there is a project with container registry tags' do
      expect(namespace).to receive(:first_project_with_container_registry_tags).and_return(project)

      expect(subject).to be_truthy
    end

    it 'returns false if there is no project with container registry tags' do
      expect(namespace).to receive(:first_project_with_container_registry_tags).and_return(nil)

      expect(subject).to be_falsey
    end
  end

  describe '#first_project_with_container_registry_tags' do
    let(:container_repository) { create(:container_repository) }
    let!(:project) { create(:project, namespace: namespace, container_repositories: [container_repository]) }

    context 'when Gitlab API is not supported' do
      before do
        stub_container_registry_config(enabled: true)
        stub_gitlab_api_client_to_support_gitlab_api(supported: false)
      end

      it 'returns the project' do
        stub_container_registry_tags(repository: :any, tags: ['tag'])

        expect(namespace.first_project_with_container_registry_tags).to eq(project)
      end

      it 'returns no project' do
        stub_container_registry_tags(repository: :any, tags: nil)

        expect(namespace.first_project_with_container_registry_tags).to be_nil
      end

      it 'does not cause N+1 query in fetching registries' do
        stub_container_registry_tags(repository: :any, tags: [])
        control = ActiveRecord::QueryRecorder.new { namespace.any_project_has_container_registry_tags? }

        other_repositories = create_list(:container_repository, 2)
        create(:project, namespace: namespace, container_repositories: other_repositories)

        expect do
          namespace.first_project_with_container_registry_tags
        end.not_to exceed_query_limit(control).with_threshold(1)
      end
    end

    context 'when Gitlab API is supported' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        stub_gitlab_api_client_to_support_gitlab_api(supported: true)
        stub_container_registry_config(enabled: true, api_url: 'http://container-registry', key: 'spec/fixtures/x509_certificate_pk.key')
      end

      it 'calls and returns GitlabApiClient.one_project_with_container_registry_tag' do
        expect(ContainerRegistry::GitlabApiClient)
          .to receive(:one_project_with_container_registry_tag)
          .with(namespace.full_path)
          .and_return(project)

        expect(namespace.first_project_with_container_registry_tags).to eq(project)
      end
    end
  end

  describe '#container_repositories_size_cache_key' do
    it 'returns the correct cache key' do
      expect(namespace.container_repositories_size_cache_key).to eq "namespaces:#{namespace.id}:container_repositories_size"
    end
  end

  describe '#container_repositories_size', :clean_gitlab_redis_cache do
    let(:project_namespace) { create(:namespace) }

    subject { project_namespace.container_repositories_size }

    context 'for a root' do
      context 'when the GitLab API is supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: true)
        end

        context 'when there are non-empty container repositories' do
          before do
            allow(project_namespace).to receive_message_chain(:all_container_repositories, :empty?).and_return(false)
          end

          shared_examples "caching the result" do
            it 'caches the result' do
              expect(Rails.cache)
                .to receive(:fetch)
                .with(project_namespace.container_repositories_size_cache_key, expires_in: 7.days)

              subject
            end
          end

          context 'when the Gitlab API client returns a value for deduplicated_size' do
            before do
              allow(ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).with(project_namespace.full_path).and_return(321)
            end

            it { is_expected.to eq(321) }

            it_behaves_like 'caching the result'
          end

          context 'when the Gitlab API client returns nil for deduplicated_size' do
            before do
              allow(ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).with(project_namespace.full_path).and_return(nil)
            end

            it { is_expected.to be_nil }

            it_behaves_like 'caching the result'
          end
        end

        context 'when all the container repositories are empty' do
          before do
            allow(project_namespace).to receive_message_chain(:all_container_repositories, :empty?).and_return(true)
          end

          it { is_expected.to eq(0) }
        end
      end

      context 'when the GitLab API is not supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: false)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'for a sub-group' do
      let(:parent_namespace) { create(:group) }
      let(:project_namespace) { create(:group, parent: parent_namespace) }

      it { is_expected.to be_nil }
    end
  end

  describe '#all_container_repositories' do
    context 'with personal namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project_namespace) { user.namespace }

      context 'with no project' do
        it { expect(project_namespace.all_container_repositories).to be_empty }
      end

      context 'with projects' do
        it "returns container repositories" do
          project = create(:project, namespace: project_namespace)
          rep = create(:container_repository, project: project)

          expect(project_namespace.all_container_repositories).to match_array([rep])
        end
      end
    end

    context 'with subgroups' do
      let_it_be(:project_namespace) { create(:group) }
      let_it_be(:subgroup1) { create(:group, parent: project_namespace) }
      let_it_be(:subgroup2) { create(:group, parent: subgroup1) }

      context 'with no project' do
        it { expect(project_namespace.all_container_repositories).to be_empty }
      end

      context 'with projects' do
        it "returns container repositories" do
          subgrp1_project = create(:project, namespace: subgroup1)
          rep1 = create(:container_repository, project: subgrp1_project)

          subgrp2_project = create(:project, namespace: subgroup2)
          rep2 = create(:container_repository, project: subgrp2_project)

          expect(project_namespace.all_container_repositories).to match_array([rep1, rep2])
        end
      end
    end
  end

  describe '#any_project_with_shared_runners_enabled?' do
    subject { namespace.any_project_with_shared_runners_enabled? }

    let!(:project_not_inheriting_shared_runners) do
      create(:project, namespace: namespace, shared_runners_enabled: false)
    end

    context 'when a child project has shared runners enabled' do
      let!(:project_inheriting_shared_runners) { create(:project, namespace: namespace, shared_runners_enabled: true) }

      it { is_expected.to eq true }
    end

    context 'when all child projects have shared runners disabled' do
      it { is_expected.to eq false }
    end
  end

  describe '.search' do
    let_it_be(:first_group) { create(:group, name: 'my first namespace', path: 'old-path') }
    let_it_be(:parent_group) { create(:group, name: 'my parent namespace', path: 'parent-path') }
    let_it_be(:second_group) { create(:group, name: 'my second namespace', path: 'new-path', parent: parent_group) }
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

    it 'defaults use_minimum_char_limit to true' do
      expect(described_class).to receive(:fuzzy_search).with(anything, anything, use_minimum_char_limit: true, exact_matches_first: false).once

      described_class.search('my namespace')
    end

    it 'passes use_minimum_char_limit if it is set' do
      expect(described_class).to receive(:fuzzy_search).with(anything, anything, use_minimum_char_limit: false, exact_matches_first: false).once

      described_class.search('my namespace', use_minimum_char_limit: false)
    end

    context 'with multiple matching namespaces' do
      let_it_be(:first_group) { create(:group, name: 'some name', path: 'z-path') }
      let_it_be(:second_group) { create(:group, name: 'some name too', path: 'a-path') }

      it 'returns exact matches first' do
        expect(described_class.search('some name', exact_matches_first: true).to_a).to eq([first_group, second_group])
      end

      it 'returns exact matches first when parents are included' do
        expect(described_class.search('some name', include_parents: true, exact_matches_first: true).to_a).to eq([first_group, second_group])
      end
    end

    context 'with project namespaces' do
      let_it_be(:project) { create(:project, namespace: parent_group, path: 'some-new-path') }
      let_it_be(:project_namespace) { project.project_namespace }

      it 'does not return project namespace' do
        search_result = described_class.search('path')

        expect(search_result).not_to include(project_namespace)
        expect(search_result).to match_array([first_group, parent_group, second_group])
      end

      it 'does not return project namespace when including parents' do
        search_result = described_class.search('path', include_parents: true)

        expect(search_result).not_to include(project_namespace)
        expect(search_result).to match_array([first_group, parent_group, second_group])
      end
    end
  end

  describe '.gfm_autocomplete_search' do
    let_it_be(:parent_group) { create(:group, path: 'parent', name: 'Parent') }
    let_it_be(:group_1) { create(:group, parent: parent_group, path: 'somepath', name: 'Your Group') }
    let_it_be(:group_2) { create(:group, path: 'noparent', name: 'My Group') }

    it 'returns partial matches on full path' do
      expect(described_class.gfm_autocomplete_search('parent/som')).to eq([group_1])
    end

    it 'returns matches on full name across multiple words' do
      expect(described_class.gfm_autocomplete_search('yourgr')).to eq([group_1])
    end

    it 'prioritizes sorting of matches that start with the query' do
      expect(described_class.gfm_autocomplete_search('pArE')).to eq([parent_group, group_1, group_2])
    end

    it 'falls back to sorting by full path' do
      expect(described_class.gfm_autocomplete_search('group')).to eq([group_2, group_1])
    end
  end

  describe '.with_statistics' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project_outside_namespace) do
      create(
        :project,
        statistics: build(
          :project_statistics,
          namespace: namespace,
          repository_size: 10,
          wiki_size: 50,
          lfs_objects_size: 20,
          build_artifacts_size: 30,
          pipeline_artifacts_size: 70,
          packages_size: 40,
          snippets_size: 60,
          uploads_size: 80
        )
      )
    end

    subject(:statistics) { described_class.with_statistics.find(namespace.id) }

    context 'with projects' do
      let_it_be(:project1) do
        create(:project,
          namespace: namespace,
          statistics: build(
            :project_statistics,
            namespace: namespace,
            repository_size: 101,
            wiki_size: 505,
            lfs_objects_size: 202,
            build_artifacts_size: 303,
            pipeline_artifacts_size: 707,
            packages_size: 404,
            snippets_size: 605,
            uploads_size: 808
          )
        )
      end

      let_it_be(:project2) do
        create(
          :project,
          namespace: namespace,
          statistics: build(
            :project_statistics,
            namespace: namespace,
            repository_size: 10,
            wiki_size: 50,
            lfs_objects_size: 20,
            build_artifacts_size: 30,
            pipeline_artifacts_size: 70,
            packages_size: 40,
            snippets_size: 60,
            uploads_size: 80
          )
        )
      end

      shared_examples 'returns statistics' do
        it "sums all project storage counters in the namespace" do
          expected_storage_size = project1.statistics.storage_size + project2.statistics.storage_size

          expect(statistics.storage_size).to eq expected_storage_size
          expect(statistics.repository_size).to eq 111
          expect(statistics.wiki_size).to eq 555
          expect(statistics.lfs_objects_size).to eq 222
          expect(statistics.build_artifacts_size).to eq 333
          expect(statistics.pipeline_artifacts_size).to eq 777
          expect(statistics.packages_size).to eq 444
          expect(statistics.snippets_size).to eq 665
          expect(statistics.uploads_size).to eq 888
        end
      end

      it_behaves_like 'returns statistics'

      context 'with relations having subquery' do
        subject(:statistics) do
          described_class.from(described_class.all, :namespaces).with_statistics.find(namespace.id)
        end

        it_behaves_like 'returns statistics'
      end
    end

    context 'without projects' do
      it "returns correct statistics" do
        expect(statistics.storage_size).to eq 0
        expect(statistics.repository_size).to eq 0
        expect(statistics.wiki_size).to eq 0
        expect(statistics.lfs_objects_size).to eq 0
        expect(statistics.build_artifacts_size).to eq 0
        expect(statistics.pipeline_artifacts_size).to eq 0
        expect(statistics.packages_size).to eq 0
        expect(statistics.snippets_size).to eq 0
        expect(statistics.uploads_size).to eq 0
      end
    end
  end

  describe '.find_by_path_or_name' do
    let_it_be(:namespace) { create(:namespace, name: 'WoW', path: 'woW') }

    it { expect(described_class.find_by_path_or_name('wow')).to eq(namespace) }
    it { expect(described_class.find_by_path_or_name('WOW')).to eq(namespace) }
    it { expect(described_class.find_by_path_or_name('unknown')).to be_nil }
  end

  describe '.find_top_level' do
    # Due to the top level scope of this spec having a create of namespace, we'll avoid possible future flakiness here.
    let(:namespace) { nil }

    subject { described_class.find_top_level }

    context 'when there are top level namespaces' do
      # Order of creation matters here as we are only taking the first result and the single
      # threaded FIFO order of creation in specs.
      let_it_be(:sub_group) { create(:group, :nested) }
      let_it_be(:another_parent_namespace) { create(:group) }
      let(:parent_namespace) { sub_group.parent }

      it { is_expected.to eq(parent_namespace) }
    end

    context 'when there are no top level namespaces' do
      it { is_expected.to be_nil }
    end
  end

  describe ".clean_path" do
    it "cleans the path and makes sure it's available", time_travel_to: '2023-04-20 00:07 -0700' do
      create :user, username: "johngitlab-etc"
      create :namespace, path: "JohnGitLab-etc1"
      create :project_setting, pages_unique_domain: 'existing-domain'
      [nil, 1, 2, 3].each do |count|
        create :namespace, path: "pickle#{count}"
      end

      expect(described_class.clean_path("-john+gitlab-ETC%.git@gmail.com")).to eq("johngitlab-ETC2")
      expect(described_class.clean_path("--%+--valid_*&%name=.git.%.atom.atom.@email.com")).to eq("valid_name")
      expect(described_class.clean_path("existing-domain")).to eq("existing-domain1")

      # when we have more than MAX_TRIES count of a path use a more randomized suffix
      expect(described_class.clean_path("pickle@gmail.com")).to eq("pickle4")
      create(:namespace, path: "pickle4")
      expect(described_class.clean_path("pickle@gmail.com")).to eq("pickle716")
      create(:namespace, path: "pickle716")
      expect(described_class.clean_path("pickle@gmail.com")).to eq("pickle717")
      expect(described_class.clean_path("--$--pickle@gmail.com")).to eq("pickle717")
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

  describe ".username_reserved?" do
    subject(:username_reserved) { described_class.username_reserved?(username) }

    let(:username) { 'capyabra' }

    let_it_be(:user) { create(:user, name: 'capybara') }
    let_it_be(:group) { create(:group, name: 'capybara-group') }
    let_it_be(:subgroup) { create(:group, parent: group, name: 'capybara-subgroup') }
    let_it_be(:project) { create(:project, group: group, name: 'capybara-project') }

    context 'when given a project name' do
      let(:username) { 'capyabra-project' }

      it { is_expected.to eq(false) }
    end

    context 'when given a sub-group name' do
      let(:username) { 'capybara-subgroup' }

      it { is_expected.to eq(false) }
    end

    context 'when given a top-level group' do
      let(:username) { 'capybara-group' }

      it { is_expected.to eq(true) }
    end

    context 'when given an existing username' do
      let(:username) { 'capybara' }

      it { is_expected.to eq(true) }
    end

    context 'when given a username with varying capitalization' do
      let(:username) { 'CaPyBaRa' }

      it { is_expected.to eq(true) }
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

  shared_examples 'disabled feature flag when traversal_ids is blank' do
    before do
      namespace.traversal_ids = []
    end

    it { is_expected.to eq false }
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

  describe '#all_projects_except_soft_deleted' do
    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group) }
      let_it_be(:child) { create(:group, parent: namespace) }
      let_it_be(:project1) { create(:project_empty_repo, namespace: namespace) }
      let_it_be(:project2) { create(:project_empty_repo, namespace: child) }
      let_it_be(:other_project) { create(:project_empty_repo) }

      before do
        reload_models(namespace, child)
      end

      it { expect(namespace.all_projects_except_soft_deleted.to_a).to match_array([project2, project1]) }
      it { expect(child.all_projects_except_soft_deleted.to_a).to match_array([project2]) }

      context 'with soft deleted projects' do
        let_it_be(:delayed_deletion_project) { create(:project, namespace: child, marked_for_deletion_at: Date.current) }

        it 'skips delayed deletion project' do
          expect(namespace.all_projects_except_soft_deleted.to_a).to match_array([project2, project1])
        end
      end
    end

    context 'when namespace is a user namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_namespace) { create(:namespace, owner: user) }
      let_it_be(:project) { create(:project, namespace: user_namespace) }
      let_it_be(:other_project) { create(:project_empty_repo) }

      before do
        reload_models(user_namespace)
      end

      it { expect(user_namespace.all_projects_except_soft_deleted.to_a).to match_array([project]) }

      context 'with soft deleted projects' do
        let_it_be(:delayed_deletion_project) { create(:project, namespace: user_namespace, marked_for_deletion_at: Date.current) }

        it 'skips delayed deletion project' do
          expect(user_namespace.all_projects_except_soft_deleted.to_a).to match_array([project])
        end
      end
    end
  end

  describe '#all_projects' do
    include_examples '#all_projects'

    # Using #self_and_descendant instead of #self_and_descendant_ids can produce
    # very slow queries.
    it 'calls self_and_descendant_ids' do
      namespace = create(:group)
      expect(namespace).to receive(:self_and_descendant_ids)
      namespace.all_projects
    end
  end

  context 'refreshing project access on updating share_with_group_lock' do
    let(:group) { create(:group, share_with_group_lock: false) }
    let(:project) { create(:project, :private, group: group) }
    let(:another_project) { create(:project, :private, group: group) }

    let_it_be(:shared_with_group_one) { create(:group) }
    let_it_be(:shared_with_group_two) { create(:group) }
    let_it_be(:group_one_user) { create(:user) }
    let_it_be(:group_two_user) { create(:user) }

    subject(:execute_update) { group.update!(share_with_group_lock: true) }

    before do
      shared_with_group_one.add_developer(group_one_user)
      shared_with_group_two.add_developer(group_two_user)
      create(:project_group_link, group: shared_with_group_one, project: project)
      create(:project_group_link, group: shared_with_group_one, project: another_project)
      create(:project_group_link, group: shared_with_group_two, project: project)
    end

    it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
        .to receive(:perform_async).with(project.id).once

      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
        .to receive(:perform_async).with(another_project.id).once

      execute_update
    end

    it 'updates authorizations leading to users from shared groups losing access', :sidekiq_inline do
      expect { execute_update }
        .to change { group_one_user.authorized_projects.include?(project) }.from(true).to(false)
        .and change { group_two_user.authorized_projects.include?(project) }.from(true).to(false)
    end

    it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
      stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in)
          .with(1.hour, [[group_one_user.id]], batch_delay: 30.seconds, batch_size: 100)
      )

      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in)
          .with(1.hour, [[group_two_user.id]], batch_delay: 30.seconds, batch_size: 100)
      )

      execute_update
    end
  end

  describe '#share_with_group_lock with subgroups' do
    context 'when creating a subgroup' do
      let(:subgroup) { create(:group, parent: root_group) }

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
      let!(:subgroup) { create(:group, parent: root_group) }

      it 'the subgroup "Share with group lock" becomes enabled' do
        root_group.update!(share_with_group_lock: true)

        expect(subgroup.reload.share_with_group_lock).to be_truthy
      end
    end

    context 'when disabling the parent group "Share with group lock" (which was already enabled)' do
      let(:root_group) { create(:group, share_with_group_lock: true) }

      context 'and the subgroup "Share with group lock" is enabled' do
        let(:subgroup) { create(:group, parent: root_group, share_with_group_lock: true) }

        it 'the subgroup "Share with group lock" does not change' do
          root_group.update!(share_with_group_lock: false)

          expect(subgroup.reload.share_with_group_lock).to be_truthy
        end
      end

      context 'but the subgroup "Share with group lock" is disabled' do
        let(:subgroup) { create(:group, parent: root_group) }

        it 'the subgroup "Share with group lock" does not change' do
          root_group.update!(share_with_group_lock: false)

          expect(subgroup.reload.share_with_group_lock?).to be_falsey
        end
      end
    end

    context 'when a group is transferred into a root group' do
      context 'when the root group "Share with group lock" is enabled' do
        let(:root_group) { create(:group, share_with_group_lock: true, organization: organization) }

        context 'when the subgroup "Share with group lock" is enabled' do
          let(:subgroup) { create(:group, share_with_group_lock: true, organization: organization) }

          it 'the subgroup "Share with group lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end

        context 'when the subgroup "Share with group lock" is disabled' do
          let(:subgroup) { create(:group, organization: organization) }

          it 'the subgroup "Share with group lock" becomes enabled' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end
      end

      context 'when the root group "Share with group lock" is disabled' do
        let(:root_group) { create(:group, organization: organization) }

        context 'when the subgroup "Share with group lock" is enabled' do
          let(:subgroup) { create(:group, share_with_group_lock: true, organization: organization) }

          it 'the subgroup "Share with group lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.share_with_group_lock).to be_truthy
          end
        end

        context 'when the subgroup "Share with group lock" is disabled' do
          let(:subgroup) { create(:group, organization: organization) }

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
      let_it_be(:root_group) { create(:group) }

      it 'returns root_ancestor for root group without a query' do
        expect { root_group.root_ancestor }.not_to exceed_query_limit(0)
      end

      it 'returns root_ancestor for nested group with a single query' do
        nested_group = create(:group, parent: root_group)
        nested_group.reload

        expect { nested_group.root_ancestor }.not_to exceed_query_limit(1)
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

      context 'when nested group references parent by id' do
        let_it_be(:nested_group) { create(:group, parent: root_group) }
        let_it_be(:deep_nested_group) { Group.new(attributes_for(:group, parent_id: nested_group.id)) }

        it 'performs a single query' do
          expect { deep_nested_group.root_ancestor }.not_to exceed_query_limit(1)
        end

        it 'returns the root ancestor' do
          expect(deep_nested_group.root_ancestor).to eq root_group
        end
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

    context 'when parent is changed' do
      let(:group) { create(:group) }
      let(:new_parent) { create(:group) }

      shared_examples 'updates root_ancestor' do
        it do
          expect { subject }.to change { group.root_ancestor }.from(group).to(new_parent)
        end
      end

      context 'by object' do
        subject { group.parent = new_parent }

        include_examples 'updates root_ancestor'
      end

      context 'by id' do
        subject { group.parent_id = new_parent.id }

        include_examples 'updates root_ancestor'
      end
    end

    context 'within a transaction' do
      context 'with a persisted parent' do
        let(:parent) { create(:group) }

        it do
          Namespace.transaction do
            group = create(:group, parent: parent)
            expect(group.root_ancestor).to eq parent
          end
        end
      end

      context 'with a non-persisted parent' do
        let(:parent) { build(:group) }

        it do
          Namespace.transaction do
            group = create(:group, parent: parent)
            expect(group.root_ancestor).to eq parent
          end
        end
      end

      context 'without a parent' do
        it do
          Namespace.transaction do
            group = create(:group)
            expect(group.root_ancestor).to eq group
          end
        end
      end
    end
  end

  describe '#full_path_before_last_save' do
    context 'when the group has no parent' do
      it 'returns the path before last save' do
        group = create(:group)

        group.update!(parent: nil)

        expect(group.full_path_before_last_save).to eq(group.path_before_last_save)
      end
    end

    context 'when a parent is assigned to a group with no previous parent' do
      it 'returns the path before last save' do
        group = create(:group, parent: nil, organization: organization)
        parent = create(:group, organization: organization)

        group.update!(parent: parent)

        expect(group.full_path_before_last_save).to eq(group.path_before_last_save.to_s)
      end
    end

    context 'when a parent is removed from the group' do
      it 'returns the parent full path' do
        parent = create(:group)
        group = create(:group, parent: parent)

        group.update!(parent: nil)

        expect(group.full_path_before_last_save).to eq("#{parent.full_path}/#{group.path}")
      end
    end

    context 'when changing parents' do
      it 'returns the previous parent full path' do
        parent = create(:group, organization: organization)
        group = create(:group, parent: parent)
        new_parent = create(:group, organization: organization)

        group.update!(parent: new_parent)

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

  describe '#first_auto_devops_config' do
    let(:instance_autodevops_status) { Gitlab::CurrentSettings.auto_devops_enabled? }

    context 'when namespace.auto_devops_enabled is not set' do
      let(:group) { create(:group) }

      it 'returns the config values using the instance setting' do
        expect(group.first_auto_devops_config).to eq({ scope: :instance, status: instance_autodevops_status })
      end

      context 'when namespace does not have auto_deveops enabled but has a parent' do
        let!(:parent) { create(:group, auto_devops_enabled: true) }
        let!(:group) { create(:group, parent: parent) }

        it 'returns the first_auto_devops_config of the parent' do
          expect(parent).to receive(:first_auto_devops_config).and_call_original

          expect(group.first_auto_devops_config).to eq({ scope: :group, status: true })
        end

        context 'then the parent is deleted' do
          it 'throws an InvalidForeignKey exception' do
            expect { parent.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
          end
        end
      end
    end

    context 'when namespace.auto_devops_enable is set' do
      let(:group) { create(:group, auto_devops_enabled: false) }

      it 'returns the correct config values' do
        expect(group.first_auto_devops_config).to eq({ scope: :group, status: false })
      end
    end
  end

  describe '#user_namespace?' do
    subject { namespace.user_namespace? }

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

  describe '#bot_user_namespace?' do
    subject { namespace.bot_user_namespace? }

    context 'when owner is a bot user user' do
      let(:user) { create(:user, :project_bot) }
      let(:namespace) { user.namespace }

      it { is_expected.to be_truthy }
    end

    context 'when owner is a non-bot user' do
      let(:user) { create(:user) }
      let(:namespace) { user.namespace }

      it { is_expected.to be_falsy }
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
    let_it_be_with_refind(:group) { create(:group) }

    it 'returns false when emails are enabled' do
      expect(group.emails_disabled?).to be_falsey
    end

    it 'returns true when emails are disabled' do
      group.emails_enabled = false

      expect(group.emails_disabled?).to be_truthy
    end
  end

  describe '#any_project_with_pages_deployed?' do
    it 'returns true if any project nested under the group has pages deployed' do
      parent_1 = create(:group) # Three projects, one with pages
      child_1_1 = create(:group, parent: parent_1) # Two projects, one with pages
      child_1_2 = create(:group, parent: parent_1) # One project, no pages
      parent_2 = create(:group) # No projects

      create(:project, group: child_1_1).tap do |project|
        create(:pages_deployment, project: project)
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
      true  | true  | Namespace::SR_ENABLED
      true  | false | Namespace::SR_ENABLED
      false | true  | Namespace::SR_DISABLED_AND_OVERRIDABLE
      false | false | Namespace::SR_DISABLED_AND_UNOVERRIDABLE
    end

    with_them do
      let(:namespace) { build(:namespace, shared_runners_enabled: shared_runners_enabled, allow_descendants_override_disabled_shared_runners: allow_descendants_override_disabled_shared_runners) }

      it 'returns the result' do
        expect(namespace.shared_runners_setting).to eq(shared_runners_setting)
      end
    end
  end

  describe '#shared_runners_setting_higher_than?' do
    using RSpec::Parameterized::TableSyntax

    where(:shared_runners_enabled, :allow_descendants_override_disabled_shared_runners, :other_setting, :result) do
      true  | true  | Namespace::SR_ENABLED                    | false
      true  | true  | Namespace::SR_DISABLED_AND_OVERRIDABLE   | true
      true  | true  | Namespace::SR_DISABLED_AND_UNOVERRIDABLE | true
      false | true  | Namespace::SR_ENABLED                    | false
      false | true  | Namespace::SR_DISABLED_AND_OVERRIDABLE   | false
      false | true  | Namespace::SR_DISABLED_AND_UNOVERRIDABLE | true
      false | false | Namespace::SR_ENABLED                    | false
      false | false | Namespace::SR_DISABLED_AND_OVERRIDABLE   | false
      false | false | Namespace::SR_DISABLED_AND_UNOVERRIDABLE | false
    end

    with_them do
      let(:namespace) { build(:namespace, shared_runners_enabled: shared_runners_enabled, allow_descendants_override_disabled_shared_runners: allow_descendants_override_disabled_shared_runners) }

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
      context 'when namespace is a group' do
        context 'when parent has shared runners disabled' do
          let(:parent) { create(:group, :shared_runners_disabled) }
          let(:group) { build(:group, shared_runners_enabled: true, parent_id: parent.id) }

          it 'is invalid' do
            expect(group).to be_invalid
            expect(group.errors[:shared_runners_enabled]).to include('cannot be enabled because parent group has shared Runners disabled')
          end
        end

        context 'when parent has shared runners disabled but allows override' do
          let(:parent) { create(:group, :shared_runners_disabled_and_overridable) }
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

    it_behaves_like 'validations called by different namespace types', :changing_shared_runners_enabled_is_allowed
  end

  describe 'validation #changing_allow_descendants_override_disabled_shared_runners_is_allowed' do
    context 'when namespace is a group' do
      context 'without a parent' do
        context 'with shared runners disabled' do
          let(:namespace) { build(:group, :shared_runners_disabled_and_overridable) }

          it 'is valid' do
            expect(namespace).to be_valid
          end
        end

        context 'with shared runners enabled' do
          let(:namespace) { build(:group) }

          it 'is invalid' do
            namespace.allow_descendants_override_disabled_shared_runners = true

            expect(namespace).to be_invalid
            expect(namespace.errors[:allow_descendants_override_disabled_shared_runners]).to include('can not be true if shared runners are enabled')
          end
        end
      end

      context 'with a parent' do
        context 'when parent does not allow shared runners' do
          let(:parent) { create(:group, :shared_runners_disabled) }
          let(:group) { build(:group, :shared_runners_disabled_and_overridable, parent_id: parent.id) }

          it 'is invalid' do
            expect(group).to be_invalid
            expect(group.errors[:allow_descendants_override_disabled_shared_runners]).to include('cannot be enabled because parent group does not allow it')
          end
        end

        context 'when parent allows shared runners and setting to true' do
          let(:parent) { create(:group, shared_runners_enabled: true) }
          let(:group) { build(:group, :shared_runners_disabled_and_overridable, parent_id: parent.id) }

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

    it_behaves_like 'validations called by different namespace types', :changing_allow_descendants_override_disabled_shared_runners_is_allowed
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

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :group }
  end

  context 'Namespaces::SyncEvent' do
    let!(:namespace) { create(:group, organization: organization) }

    let_it_be(:new_namespace1) { create(:group, organization: organization) }
    let_it_be(:new_namespace2) { create(:group, organization: organization) }

    context 'when creating the namespace' do
      it 'creates a namespaces_sync_event record' do
        expect(namespace.sync_events.count).to eq(1)
      end

      it 'enqueues ProcessSyncEventsWorker' do
        expect(Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)

        create(:namespace)
      end
    end

    context 'when updating namespace parent_id' do
      it 'creates a namespaces_sync_event record' do
        expect do
          namespace.update!(parent_id: new_namespace1.id)
        end.to change(Namespaces::SyncEvent, :count).by(1)

        expect(namespace.sync_events.count).to eq(2)
      end

      it 'creates a namespaces_sync_event for the parent and all the descendent namespaces' do
        children_namespaces = create_list(:group, 2, parent_id: namespace.id, organization: organization)
        grand_children_namespaces = create_list(:group, 2, parent_id: children_namespaces.first.id, organization:
                                                organization)
        expect(Namespaces::ProcessSyncEventsWorker).to receive(:perform_async).exactly(:once)
        Namespaces::SyncEvent.delete_all

        expect do
          namespace.update!(parent_id: new_namespace1.id)
        end.to change(Namespaces::SyncEvent, :count).by(5)

        expected_ids = [namespace.id] + children_namespaces.map(&:id) + grand_children_namespaces.map(&:id)
        expect(Namespaces::SyncEvent.pluck(:namespace_id)).to match_array(expected_ids)
      end

      it 'enqueues ProcessSyncEventsWorker' do
        expect(Namespaces::ProcessSyncEventsWorker).to receive(:perform_async)

        namespace.update!(parent_id: new_namespace1.id)
      end
    end

    context 'when updating namespace other attribute' do
      it 'creates a namespaces_sync_event record' do
        expect do
          namespace.update!(name: 'hello')
        end.not_to change(Namespaces::SyncEvent, :count)
      end
    end

    context 'in the same transaction' do
      context 'when updating different parent_id' do
        it 'creates two namespaces_sync_event records' do
          expect do
            Namespace.transaction do
              namespace.update!(parent_id: new_namespace1.id)
              namespace.update!(parent_id: new_namespace2.id)
            end
          end.to change(Namespaces::SyncEvent, :count).by(2)

          expect(namespace.sync_events.count).to eq(3)
        end
      end

      context 'when updating the same parent_id' do
        it 'creates one namespaces_sync_event record' do
          expect do
            Namespace.transaction do
              namespace.update!(parent_id: new_namespace1.id)
              namespace.update!(parent_id: new_namespace1.id)
            end
          end.to change(Namespaces::SyncEvent, :count).by(1)

          expect(namespace.sync_events.count).to eq(2)
        end
      end
    end
  end

  describe 'serialization' do
    let(:object) { build(:namespace) }

    it_behaves_like 'blocks unsafe serialization'
  end

  describe '#certificate_based_clusters_enabled?' do
    context 'with ff disabled' do
      before do
        stub_feature_flags(certificate_based_clusters: false)
      end

      context 'with a cluster_enabled_grant' do
        it 'is truthy' do
          create(:cluster_enabled_grant, namespace: namespace)

          expect(namespace.certificate_based_clusters_enabled?).to be_truthy
        end
      end

      context 'without a cluster_enabled_grant' do
        it 'is falsy' do
          expect(namespace.certificate_based_clusters_enabled?).to be_falsy
        end
      end
    end

    context 'with ff enabled' do
      before do
        stub_feature_flags(certificate_based_clusters: true)
      end

      context 'with a cluster_enabled_grant' do
        it 'is truthy' do
          create(:cluster_enabled_grant, namespace: namespace)

          expect(namespace.certificate_based_clusters_enabled?).to be_truthy
        end
      end

      context 'without a cluster_enabled_grant' do
        it 'is truthy' do
          expect(namespace.certificate_based_clusters_enabled?).to be_truthy
        end
      end
    end
  end

  describe '#web_url' do
    let_it_be(:group) { create(:group) }

    it 'returns the canonical URL' do
      expect(group.web_url).to include("groups/#{group.name}")
    end

    context 'nested group' do
      let(:nested_group) { create(:group, :nested) }

      it { expect(nested_group.web_url).to include("groups/#{nested_group.full_path}") }
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns organization_id' do
      organization = build_stubbed(:organization)
      namespace = build_stubbed(:namespace, organization: organization)

      expect(namespace.uploads_sharding_key).to eq(organization_id: organization.id)
    end
  end
end

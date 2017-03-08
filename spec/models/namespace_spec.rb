require 'spec_helper'

describe Namespace, models: true do
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
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:human_name) }
    it { is_expected.to respond_to(:to_param) }
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
      statistics = Namespace.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 666
      expect(statistics.repository_size).to eq 111
      expect(statistics.lfs_objects_size).to eq 222
      expect(statistics.build_artifacts_size).to eq 333
    end

    it "correctly handles namespaces without projects" do
      statistics = Namespace.with_statistics.find(namespace.id)

      expect(statistics.storage_size).to eq 0
      expect(statistics.repository_size).to eq 0
      expect(statistics.lfs_objects_size).to eq 0
      expect(statistics.build_artifacts_size).to eq 0
    end
  end

  describe '#move_dir' do
    before do
      @namespace = create :namespace
      @project = create(:empty_project, namespace: @namespace)
      allow(@namespace).to receive(:path_changed?).and_return(true)
    end

    it "raises error when directory exists" do
      expect { @namespace.move_dir }.to raise_error("namespace directory cannot be moved")
    end

    it "moves dir if path changed" do
      new_path = @namespace.path + "_new"
      allow(@namespace).to receive(:path_was).and_return(@namespace.path)
      allow(@namespace).to receive(:path).and_return(new_path)
      expect(@namespace).to receive(:remove_exports!)
      expect(@namespace.move_dir).to be_truthy
    end

    context "when any project has container tags" do
      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags('tag')

        create(:empty_project, namespace: @namespace)

        allow(@namespace).to receive(:path_was).and_return(@namespace.path)
        allow(@namespace).to receive(:path).and_return('new_path')
      end

      it { expect { @namespace.move_dir }.to raise_error('Namespace cannot be moved, because at least one project has tags in container registry') }
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

  describe :rm_dir do
    let!(:project) { create(:empty_project, namespace: namespace) }
    let!(:path) { File.join(Gitlab.config.repositories.storages.default, namespace.full_path) }

    it "removes its dirs when deleted" do
      namespace.destroy

      expect(File.exist?(path)).to be(false)
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

    it { expect(Namespace.find_by_path_or_name('wow')).to eq(@namespace) }
    it { expect(Namespace.find_by_path_or_name('WOW')).to eq(@namespace) }
    it { expect(Namespace.find_by_path_or_name('unknown')).to eq(nil) }
  end

  describe ".clean_path" do
    let!(:user)       { create(:user, username: "johngitlab-etc") }
    let!(:namespace)  { create(:namespace, path: "JohnGitLab-etc1") }

    it "cleans the path and makes sure it's available" do
      expect(Namespace.clean_path("-john+gitlab-ETC%.git@gmail.com")).to eq("johngitlab-ETC2")
      expect(Namespace.clean_path("--%+--valid_*&%name=.git.%.atom.atom.@email.com")).to eq("valid_name")
    end
  end

  describe '#ancestors' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.ancestors).to eq([group, nested_group, deep_nested_group])
      expect(deep_nested_group.ancestors).to eq([group, nested_group])
      expect(nested_group.ancestors).to eq([group])
      expect(group.ancestors).to eq([])
    end
  end

  describe '#descendants' do
    let!(:group) { create(:group) }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.descendants.to_a).to eq([])
      expect(deep_nested_group.descendants.to_a).to eq([very_deep_nested_group])
      expect(nested_group.descendants.to_a).to eq([deep_nested_group, very_deep_nested_group])
      expect(group.descendants.to_a).to eq([nested_group, deep_nested_group, very_deep_nested_group])
    end
  end

  describe '#user_ids_for_project_authorizations' do
    it 'returns the user IDs for which to refresh authorizations' do
      expect(namespace.user_ids_for_project_authorizations).
        to eq([namespace.owner_id])
    end
  end
end

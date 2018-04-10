require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170503140202_turn_nested_groups_into_regular_groups_for_mysql.rb')

describe TurnNestedGroupsIntoRegularGroupsForMysql do
  let!(:parent_group) { create(:group) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:child_group) { create(:group, parent: parent_group) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:project) { create(:project, :legacy_storage, :empty_repo, namespace: child_group) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:member) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:migration) { described_class.new }

  before do
    parent_group.add_developer(member)

    allow(migration).to receive(:run_migration?).and_return(true)
    allow(migration).to receive(:verbose).and_return(false)
  end

  describe '#up' do
    let(:updated_project) do
      # path_with_namespace is memoized in an instance variable so we retrieve a
      # new row here to work around that.
      Project.find(project.id)
    end

    before do
      migration.up
    end

    it 'unsets the parent_id column' do
      expect(Namespace.where('parent_id IS NOT NULL').any?).to eq(false)
    end

    it 'adds members of parent groups as members to the migrated group' do
      is_member = child_group.members
        .where(user_id: member, access_level: Gitlab::Access::DEVELOPER).any?

      expect(is_member).to eq(true)
    end

    it 'update the path of the nested group' do
      child_group.reload

      expect(child_group.path).to eq("#{parent_group.name}-#{child_group.name}")
    end

    it 'renames projects of the nested group' do
      expect(updated_project.full_path)
        .to eq("#{parent_group.name}-#{child_group.name}/#{updated_project.path}")
    end

    it 'renames the repository of any projects' do
      expect(updated_project.repository.path)
        .to end_with("#{parent_group.name}-#{child_group.name}/#{updated_project.path}.git")

      expect(File.directory?(updated_project.repository.path)).to eq(true)
    end

    it 'creates a redirect route for renamed projects' do
      exists = RedirectRoute
        .where(source_type: 'Project', source_id: project.id)
        .any?

      expect(exists).to eq(true)
    end
  end
end

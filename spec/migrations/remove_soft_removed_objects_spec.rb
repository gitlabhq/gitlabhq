require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171207150343_remove_soft_removed_objects.rb')

describe RemoveSoftRemovedObjects, :migration do
  describe '#up' do
    it 'removes various soft removed objects' do
      5.times do
        create_with_deleted_at(:issue)
      end

      regular_issue = create(:issue) # rubocop:disable RSpec/FactoriesInMigrationSpecs

      run_migration

      expect(Issue.count).to eq(1)
      expect(Issue.first).to eq(regular_issue)
    end

    it 'removes the temporary indexes once soft removed data has been removed' do
      migration = described_class.new

      run_migration

      disable_migrations_output do
        expect(migration.temporary_index_exists?(Issue)).to eq(false)
      end
    end

    it 'removes routes of soft removed personal namespaces' do
      namespace = create_with_deleted_at(:namespace)
      group = create(:group) # rubocop:disable RSpec/FactoriesInMigrationSpecs

      expect(Route.where(source: namespace).exists?).to eq(true)
      expect(Route.where(source: group).exists?).to eq(true)

      run_migration

      expect(Route.where(source: namespace).exists?).to eq(false)
      expect(Route.where(source: group).exists?).to eq(true)
    end

    it 'schedules the removal of soft removed groups' do
      group = create_with_deleted_at(:group)
      admin = create(:user, admin: true) # rubocop:disable RSpec/FactoriesInMigrationSpecs

      expect_any_instance_of(GroupDestroyWorker)
        .to receive(:perform)
        .with(group.id, admin.id)

      run_migration
    end

    it 'does not remove soft removed groups when no admin user could be found' do
      create_with_deleted_at(:group)

      expect_any_instance_of(GroupDestroyWorker)
        .not_to receive(:perform)

      run_migration
    end
  end

  def run_migration
    disable_migrations_output do
      migrate!
    end
  end

  def create_with_deleted_at(*args)
    row = create(*args) # rubocop:disable RSpec/FactoriesInMigrationSpecs

    # We set "deleted_at" this way so we don't run into any column cache issues.
    row.class.where(id: row.id).update_all(deleted_at: 1.year.ago)

    row
  end
end

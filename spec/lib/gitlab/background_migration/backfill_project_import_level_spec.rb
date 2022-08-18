# frozen_string_literal: true

require 'spec_helper'
require_migration!

# rubocop:disable Layout/HashAlignment
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectImportLevel do
  let(:migration) do
    described_class.new(
      start_id:         table(:namespaces).minimum(:id),
      end_id:           table(:namespaces).maximum(:id),
      batch_table:      :namespaces,
      batch_column:     :id,
      sub_batch_size:   2,
      pause_ms:         0,
      connection:       ApplicationRecord.connection
    )
  end
  # rubocop:enable Layout/HashAlignment

  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }

  let!(:user_namespace) do
    namespaces_table.create!(
      name: 'user_namespace',
      path: 'user_namespace',
      type: 'User',
      project_creation_level: 100
    )
  end

  let!(:group_namespace_nil) do
    namespaces_table.create!(
      name: 'group_namespace_nil',
      path: 'group_namespace_nil',
      type: 'Group',
      project_creation_level: nil
    )
  end

  let!(:group_namespace_0) do
    namespaces_table.create!(
      name: 'group_namespace_0',
      path: 'group_namespace_0',
      type: 'Group',
      project_creation_level: 0
    )
  end

  let!(:group_namespace_1) do
    namespaces_table.create!(
      name: 'group_namespace_1',
      path: 'group_namespace_1',
      type: 'Group',
      project_creation_level: 1
    )
  end

  let!(:group_namespace_2) do
    namespaces_table.create!(
      name: 'group_namespace_2',
      path: 'group_namespace_2',
      type: 'Group',
      project_creation_level: 2
    )
  end

  let!(:group_namespace_9999) do
    namespaces_table.create!(
      name: 'group_namespace_9999',
      path: 'group_namespace_9999',
      type: 'Group',
      project_creation_level: 9999
    )
  end

  subject(:perform_migration) { migration.perform }

  before do
    namespace_settings_table.create!(namespace_id: user_namespace.id)
    namespace_settings_table.create!(namespace_id: group_namespace_nil.id)
    namespace_settings_table.create!(namespace_id: group_namespace_0.id)
    namespace_settings_table.create!(namespace_id: group_namespace_1.id)
    namespace_settings_table.create!(namespace_id: group_namespace_2.id)
    namespace_settings_table.create!(namespace_id: group_namespace_9999.id)
  end

  describe 'Groups' do
    using RSpec::Parameterized::TableSyntax

    where(:namespace_id, :prev_level, :new_level) do
      lazy { group_namespace_0.id }   | ::Gitlab::Access::OWNER | ::Gitlab::Access::NO_ACCESS
      lazy { group_namespace_1.id }   | ::Gitlab::Access::OWNER | ::Gitlab::Access::MAINTAINER
      lazy { group_namespace_2.id }   | ::Gitlab::Access::OWNER | ::Gitlab::Access::DEVELOPER
    end

    with_them do
      it 'backfills the correct project_import_level of Group namespaces' do
        expect { perform_migration }
          .to change { namespace_settings_table.find_by(namespace_id: namespace_id).project_import_level }
          .from(prev_level).to(new_level)
      end
    end

    it 'does not update `User` namespaces or values outside range' do
      expect { perform_migration }
        .not_to change { namespace_settings_table.find_by(namespace_id: user_namespace.id).project_import_level }

      expect { perform_migration }
        .not_to change { namespace_settings_table.find_by(namespace_id: group_namespace_9999.id).project_import_level }
    end

    it 'maintains default import_level if creation_level is nil' do
      project_import_level = namespace_settings_table.find_by(namespace_id: group_namespace_nil.id).project_import_level

      expect { perform_migration }
        .not_to change { project_import_level }

      expect(project_import_level).to eq(::Gitlab::Access::OWNER)
    end
  end
end

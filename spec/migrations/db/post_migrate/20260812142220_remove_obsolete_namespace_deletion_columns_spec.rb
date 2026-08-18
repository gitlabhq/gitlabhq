# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveObsoleteNamespaceDeletionColumns, feature_category: :groups_and_projects do
  let(:connection) { described_class.new.connection }

  describe '#up' do
    before do
      # The columns are absent from the canonical schema (they only exist on
      # staging where the reverted migration ran). Simulate their presence so
      # the migration has something to remove.
      unless connection.column_exists?(:namespaces, :marked_for_deletion_at)
        connection.add_column(:namespaces, :marked_for_deletion_at, :date)
      end

      unless connection.column_exists?(:namespaces, :marked_for_deletion_by_user_id)
        connection.add_column(:namespaces, :marked_for_deletion_by_user_id, :integer)
      end
    end

    it 'removes both columns', :aggregate_failures do
      migrate!

      expect(connection.column_exists?(:namespaces, :marked_for_deletion_at)).to be(false)
      expect(connection.column_exists?(:namespaces, :marked_for_deletion_by_user_id)).to be(false)
    end

    it 'is idempotent when columns are already absent' do
      connection.remove_column(:namespaces, :marked_for_deletion_at)
      connection.remove_column(:namespaces, :marked_for_deletion_by_user_id)

      expect { migrate! }.not_to raise_error
    end
  end

  describe '#down' do
    it 'is a no-op and leaves columns absent', :aggregate_failures do
      migrate!
      schema_migrate_down!

      expect(connection.column_exists?(:namespaces, :marked_for_deletion_at)).to be(false)
      expect(connection.column_exists?(:namespaces, :marked_for_deletion_by_user_id)).to be(false)
    end
  end
end

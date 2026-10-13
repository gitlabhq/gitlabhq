# frozen_string_literal: true

require 'spec_helper'
require_migration!
require_migration!('drop_merge_request_diff_files_archived_reverse_sync_trigger')

RSpec.describe DisableMergeRequestDiffFilesArchivedReverseSyncTrigger, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }
  let(:drop_migration) { DropMergeRequestDiffFilesArchivedReverseSyncTrigger.new }
  let(:connection) { migration.connection }

  context 'when the reverse sync trigger does not exist', :aggregate_failures do
    it 'does nothing in both directions' do
      reversible_migration do |test|
        test.before -> { expect(trigger_exists?).to be(false) }
        test.after -> { expect(trigger_exists?).to be(false) }
      end
    end
  end

  context 'when the reverse sync trigger exists', :aggregate_failures do
    before do
      # Recreate the state where the drop migration did not complete.
      drop_migration.down
    end

    after do
      drop_migration.up
    end

    it 'disables the trigger on the parent and on every partition, and re-enables it on down' do
      reversible_migration do |test|
        test.before -> {
          expect(trigger_states.size).to be > 1
          expect(trigger_states).to all(eq('O'))
        }

        test.after -> {
          expect(trigger_exists?).to be(true)
          expect(trigger_states).to all(eq('D'))
        }
      end
    end
  end

  private

  def trigger_exists?
    migration.send(:trigger_exists?, described_class::SOURCE_TABLE, described_class::REVERSE_TRIGGER_NAME)
  end

  # Returns the tgenabled value of the trigger on the parent and on each partition clone.
  def trigger_states
    connection.select_values(<<~SQL)
      SELECT t.tgenabled
      FROM pg_trigger t
      WHERE NOT t.tgisinternal
        AND t.tgname = #{connection.quote(described_class::REVERSE_TRIGGER_NAME)}
    SQL
  end
end

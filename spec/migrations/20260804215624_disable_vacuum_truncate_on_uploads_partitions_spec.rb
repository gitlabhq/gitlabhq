# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DisableVacuumTruncateOnUploadsPartitions, migration: :gitlab_main, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  def uploads_partitions
    Gitlab::Database::PostgresPartition.for_parent_table('uploads').map(&:identifier)
  end

  def partitions_with_vacuum_truncate_disabled
    uploads_partitions.select do |identifier|
      connection.select_value(<<~SQL)
        SELECT true FROM pg_class
        WHERE oid = #{connection.quote(identifier)}::regclass
          AND reloptions @> ARRAY['vacuum_truncate=false']
      SQL
    end
  end

  context 'when on .com_except_jh' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    describe '#up' do
      it 'sets vacuum_truncate = false on every uploads partition' do
        expect { migrate! }
          .to change { partitions_with_vacuum_truncate_disabled }
          .from(be_empty)
          .to(match_array(uploads_partitions))
      end
    end

    describe '#down' do
      it 'resets vacuum_truncate on every uploads partition' do
        migrate!

        expect { schema_migrate_down! }
          .to change { partitions_with_vacuum_truncate_disabled }
          .from(match_array(uploads_partitions))
          .to(be_empty)
      end
    end
  end

  context 'when not on .com_except_jh' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    describe '#up' do
      it 'does not change any partition reloptions' do
        expect { migrate! }.not_to change { partitions_with_vacuum_truncate_disabled }
      end
    end

    describe '#down' do
      it 'does not change any partition reloptions' do
        migrate!

        expect { schema_migrate_down! }.not_to change { partitions_with_vacuum_truncate_disabled }
      end
    end
  end
end

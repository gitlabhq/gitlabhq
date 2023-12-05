# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForCiPipelinesPipelineIdBigintForSelfHost, feature_category: :continuous_integration do
  let(:connection) { active_record_base.connection }

  before do
    connection.execute('ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id TYPE integer')
    connection.execute('ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id_convert_to_bigint TYPE bigint')
  end

  it_behaves_like(
    'swap conversion columns',
    table_name: :ci_pipelines,
    from: :auto_canceled_by_id,
    to: :auto_canceled_by_id_convert_to_bigint
  )

  context 'when foreign key names are different' do
    before do
      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_262d4c2d19)
        connection.execute(
          'ALTER TABLE "ci_pipelines" RENAME CONSTRAINT "fk_262d4c2d19" TO "fk_4_auto_canceled_by_id"'
        )
      end

      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_67e4288f3a)
        connection.execute(
          'ALTER TABLE "ci_pipelines" RENAME CONSTRAINT "fk_67e4288f3a" TO "fk_4_auto_canceled_by_id_convert_to_bigint"'
        )
      end
    end

    after do
      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_4_auto_canceled_by_id)
        connection.execute(
          'ALTER TABLE "ci_pipelines" RENAME CONSTRAINT "fk_4_auto_canceled_by_id" TO "fk_262d4c2d19"'
        )
      end

      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_4_auto_canceled_by_id_convert_to_bigint)
        connection.execute(
          'ALTER TABLE "ci_pipelines" RENAME CONSTRAINT "fk_4_auto_canceled_by_id_convert_to_bigint" TO "fk_67e4288f3a"'
        )
      end
    end

    it 'swaps the foreign key properly' do
      disable_migrations_output do
        recorder = ActiveRecord::QueryRecorder.new { migrate! }
        expect(recorder.log).to include(
          /RENAME CONSTRAINT "fk_4_auto_canceled_by_id_convert_to_bigint" TO "temp_name_for_renaming"/
        )
        expect(recorder.log).to include(
          /RENAME CONSTRAINT "fk_4_auto_canceled_by_id" TO "fk_4_auto_canceled_by_id_convert_to_bigint"/
        )
        expect(recorder.log).to include(/RENAME CONSTRAINT "temp_name_for_renaming" TO "fk_4_auto_canceled_by_id"/)
      end
    end
  end

  context 'when foreign key is missing' do
    before do
      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_262d4c2d19)
        connection.remove_foreign_key(:ci_pipelines, name: :fk_262d4c2d19)
      end

      if connection.foreign_key_exists?(:ci_pipelines, name: :fk_4_auto_canceled_by_id)
        connection.remove_foreign_key(:ci_pipelines, name: :fk_4_auto_canceled_by_id)
      end
    end

    after do
      # Need to add the foreign key back or it will fail the other tests
      connection.add_foreign_key(
        :ci_pipelines, :ci_pipelines,
        name: :fk_262d4c2d19, column: :auto_canceled_by_id, on_delete: :nullify
      )
    end

    it 'raises error' do
      disable_migrations_output do
        expect { migrate! }.to raise_error(/Required foreign key for .* is missing./)
      end
    end
  end
end

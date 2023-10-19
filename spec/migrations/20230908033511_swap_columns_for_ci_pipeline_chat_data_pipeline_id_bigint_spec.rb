# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForCiPipelineChatDataPipelineIdBigint, feature_category: :continuous_integration do
  let(:connection) { active_record_base.connection }
  let(:table_ci_pipeline_chat_data) { table(:ci_pipeline_chat_data) }

  before do
    connection.execute('ALTER TABLE ci_pipeline_chat_data ALTER COLUMN pipeline_id TYPE integer')
    connection.execute('ALTER TABLE ci_pipeline_chat_data ALTER COLUMN pipeline_id_convert_to_bigint TYPE bigint')
  end

  it 'swaps columns' do
    disable_migrations_output do
      reversible_migration do |migration|
        migration.before -> {
          expect(column('pipeline_id').sql_type).to eq('integer')
          expect(column('pipeline_id_convert_to_bigint').sql_type).to eq('bigint')
        }

        migration.after -> {
          expect(column('pipeline_id').sql_type).to eq('bigint')
          expect(column('pipeline_id_convert_to_bigint').sql_type).to eq('integer')
        }
      end
    end
  end

  context 'when legacy foreign key exists' do
    before do
      if connection.foreign_key_exists?(
        :ci_pipeline_chat_data, name: :fk_64ebfab6b3)
        connection.remove_foreign_key(:ci_pipeline_chat_data, :ci_pipelines,
          name: :fk_64ebfab6b3)
      end

      connection.add_foreign_key(:ci_pipeline_chat_data, :ci_pipelines, column: :pipeline_id,
        name: :fk_rails_64ebfab6b3)
    end

    it 'renames the legacy foreign key fk_rails_64ebfab6b3' do
      expect(connection.foreign_key_exists?(:ci_pipeline_chat_data, name: :fk_rails_64ebfab6b3)).to be_truthy
      expect(connection.foreign_key_exists?(:ci_pipeline_chat_data, name: :fk_64ebfab6b3)).to be_falsy

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            expect(column('pipeline_id').sql_type).to eq('integer')
            expect(column('pipeline_id_convert_to_bigint').sql_type).to eq('bigint')
          }

          migration.after -> {
            expect(column('pipeline_id').sql_type).to eq('bigint')
            expect(column('pipeline_id_convert_to_bigint').sql_type).to eq('integer')

            expect(connection.foreign_key_exists?(:ci_pipeline_chat_data, name: :fk_rails_64ebfab6b3)).to be_falsy
            expect(connection.foreign_key_exists?(:ci_pipeline_chat_data, name: :fk_64ebfab6b3)).to be_truthy
          }
        end
      end
    end
  end

  private

  def column(name)
    table_ci_pipeline_chat_data.reset_column_information
    table_ci_pipeline_chat_data.columns.find { |c| c.name == name.to_s }
  end
end

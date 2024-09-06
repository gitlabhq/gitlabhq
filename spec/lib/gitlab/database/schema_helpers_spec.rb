# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaHelpers, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:migration_context) do
    ActiveRecord::Migration
      .new
      .extend(described_class)
      .extend(Gitlab::Database::MigrationHelpers)
  end

  describe '#reset_trigger_function' do
    let(:trigger_function_name) { 'existing_trigger_function' }

    before do
      connection.execute(<<~SQL)
        CREATE FUNCTION #{trigger_function_name}() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
        BEGIN
          NEW."bigint_column" := NEW."integer_column";
          RETURN NEW;
        END;
        $$;
      SQL
    end

    it 'resets' do
      recorder = ActiveRecord::QueryRecorder.new do
        migration_context.reset_trigger_function(trigger_function_name)
      end
      expect(recorder.log).to include(/ALTER FUNCTION "existing_trigger_function" RESET ALL/)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResetOnColumnErrors, :delete, feature_category: :shared do
  let(:test_attribute_table) do
    Class.new(ApplicationRecord) do
      include FromUnion

      self.table_name = '_test_attribute_table'

      def self.name
        'TestAttributeTable'
      end
    end
  end

  before(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
        CREATE TABLE _test_attribute_table (
          id serial NOT NULL PRIMARY KEY,
          created_at timestamptz NOT NULL
        );
    SQL
  end

  after(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
        DROP TABLE _test_attribute_table
    SQL
  end

  describe 'resetting on union errors' do
    let(:expected_error_message) { /must have the same number of columns/ }

    def load_query
      scopes = [
        test_attribute_table.select('*'),
        test_attribute_table.select(test_attribute_table.column_names.join(','))
      ]

      test_attribute_table.from_union(scopes).load
    end

    context 'with mismatched columns due to schema cache' do
      before do
        load_query

        ApplicationRecord.connection.execute(<<~SQL)
          ALTER TABLE _test_attribute_table ADD COLUMN _test_new_column int;
        SQL
      end

      after do
        ApplicationRecord.connection.execute(<<~SQL)
          ALTER TABLE _test_attribute_table DROP COLUMN _test_new_column;
        SQL

        test_attribute_table.reset_column_information
      end

      it 'resets column information when encountering an UNION error' do
        expect do
          load_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
          .and change { test_attribute_table.column_names }
            .from(%w[id created_at]).to(%w[id created_at _test_new_column])

        # Subsequent query load from new schema cache, so no more error
        expect do
          load_query
        end.not_to raise_error
      end

      it 'logs when column is reset' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error)
          .with(hash_including("extra.reset_model_name" => "TestAttributeTable"))
          .and_call_original

        expect do
          load_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end
    end

    context 'with mismatched columns due to coding error' do
      def load_mismatched_query
        scopes = [
          test_attribute_table.select("id"),
          test_attribute_table.select("id, created_at")
        ]

        test_attribute_table.from_union(scopes).load
      end

      it 'limits reset_column_information calls' do
        expect(test_attribute_table).to receive(:reset_column_information).and_call_original

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)

        expect(test_attribute_table).not_to receive(:reset_column_information)

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end

      it 'does reset_column_information after some time has passed' do
        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)

        travel_to(described_class::MAX_RESET_PERIOD.from_now + 1.minute)
        expect(test_attribute_table).to receive(:reset_column_information).and_call_original

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end
    end
  end

  describe 'resetting on missing column error on save' do
    let(:expected_error_message) { /unknown attribute '_test_new_column'/ }

    context 'with mismatched columns due to schema cache' do
      let!(:attrs) { test_attribute_table.new.attributes }

      def initialize_with_new_column
        test_attribute_table.new(attrs.merge(_test_new_column: 123))
      end

      before do
        ApplicationRecord.connection.execute(<<~SQL)
          ALTER TABLE _test_attribute_table ADD COLUMN _test_new_column int;
        SQL
      end

      after do
        ApplicationRecord.connection.execute(<<~SQL)
          ALTER TABLE _test_attribute_table DROP COLUMN _test_new_column;
        SQL

        test_attribute_table.reset_column_information
      end

      it 'resets column information when encountering an UnknownAttributeError' do
        expect do
          initialize_with_new_column
        end.to raise_error(ActiveModel::UnknownAttributeError, expected_error_message)
              .and change { test_attribute_table.column_names }
                 .from(%w[id created_at]).to(%w[id created_at _test_new_column])

        # Subsequent query load from new schema cache, so no more error
        expect do
          initialize_with_new_column
        end.not_to raise_error
      end

      it 'logs when column is reset' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error)
          .with(hash_including("extra.reset_model_name" => "TestAttributeTable"))
          .and_call_original

        expect do
          initialize_with_new_column
        end.to raise_error(ActiveModel::UnknownAttributeError, expected_error_message)
      end

      context 'when reset_column_information_on_statement_invalid FF is disabled' do
        before do
          stub_feature_flags(reset_column_information_on_statement_invalid: false)
        end

        it 'does not reset column information' do
          expect do
            initialize_with_new_column
          end.to raise_error(ActiveModel::UnknownAttributeError, expected_error_message)
             .and not_change { test_attribute_table.column_names }
        end
      end
    end
  end
end

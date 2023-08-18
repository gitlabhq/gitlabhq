# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResetOnUnionError, :delete, feature_category: :shared do
  let(:test_unioned_model) do
    Class.new(ApplicationRecord) do
      include FromUnion

      self.table_name = '_test_unioned_model'

      def self.name
        'TestUnion'
      end
    end
  end

  before(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE _test_unioned_model (
        id serial NOT NULL PRIMARY KEY,
        created_at timestamptz NOT NULL
      );
    SQL
  end

  after(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
      DROP TABLE _test_unioned_model
    SQL
  end

  context 'with mismatched columns due to schema cache' do
    def load_query
      scopes = [
        test_unioned_model.select('*'),
        test_unioned_model.select(test_unioned_model.column_names.join(','))
      ]

      test_unioned_model.from_union(scopes).load
    end

    before do
      load_query

      ApplicationRecord.connection.execute(<<~SQL)
        ALTER TABLE _test_unioned_model ADD COLUMN _test_new_column int;
      SQL
    end

    after do
      ApplicationRecord.connection.execute(<<~SQL)
        ALTER TABLE _test_unioned_model DROP COLUMN _test_new_column;
      SQL

      test_unioned_model.reset_column_information
    end

    it 'resets column information when encountering an UNION error' do
      expect do
        load_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)
        .and change { test_unioned_model.column_names }.from(%w[id created_at]).to(%w[id created_at _test_new_column])

      # Subsequent query load from new schema cache, so no more error
      expect do
        load_query
      end.not_to raise_error
    end

    it 'logs when column is reset' do
      expect(Gitlab::ErrorTracking::Logger).to receive(:error)
        .with(hash_including("extra.reset_model_name" => "TestUnion"))
        .and_call_original

      expect do
        load_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)
    end

    context 'when reset_column_information_on_statement_invalid FF is disabled' do
      before do
        stub_feature_flags(reset_column_information_on_statement_invalid: false)
      end

      it 'does not reset column information' do
        expect do
          load_query
        end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)
          .and not_change { test_unioned_model.column_names }
      end
    end
  end

  context 'with mismatched columns due to coding error' do
    def load_mismatched_query
      scopes = [
        test_unioned_model.select("id"),
        test_unioned_model.select("id, created_at")
      ]

      test_unioned_model.from_union(scopes).load
    end

    it 'limits reset_column_information calls' do
      expect(test_unioned_model).to receive(:reset_column_information).and_call_original

      expect do
        load_mismatched_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)

      expect(test_unioned_model).not_to receive(:reset_column_information)

      expect do
        load_mismatched_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)
    end

    it 'does reset_column_information after some time has passed' do
      expect do
        load_mismatched_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)

      travel_to(described_class::MAX_RESET_PERIOD.from_now + 1.minute)
      expect(test_unioned_model).to receive(:reset_column_information).and_call_original

      expect do
        load_mismatched_query
      end.to raise_error(ActiveRecord::StatementInvalid, /must have the same number of columns/)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResetOnColumnErrors, :delete, feature_category: :shared, query_analyzers: false do
  let(:test_reviewer_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_reviewers_table'

      def self.name
        'TestReviewer'
      end
    end
  end

  let(:test_attribute_reviewer_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_attribute_reviewers_table'

      belongs_to :test_attribute, class_name: 'TestAttribute'
      belongs_to :test_reviewer, class_name: 'TestReviewer'

      def self.name
        'TestAttributeReviewer'
      end
    end
  end

  let(:test_attribute_model) do
    Class.new(ApplicationRecord) do
      include FromUnion

      self.table_name = '_test_attribute_table'

      has_many :attribute_reviewers, class_name: 'TestAttributeReviewer'
      has_many :reviewers, class_name: 'TestReviewer', through: :attribute_reviewers, source: :test_reviewer

      def self.name
        'TestAttribute'
      end
    end
  end

  before do
    stub_const('TestReviewer', test_reviewer_model)
    stub_const('TestAttributeReviewer', test_attribute_reviewer_model)
    stub_const('TestAttribute', test_attribute_model)
  end

  before(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
        CREATE TABLE _test_attribute_table (
          id serial NOT NULL PRIMARY KEY,
          created_at timestamptz NOT NULL
        );

        CREATE TABLE _test_attribute_reviewers_table (
          test_attribute_id bigint,
          test_reviewer_id bigint
        );

        CREATE TABLE _test_reviewers_table (
          id serial NOT NULL PRIMARY KEY,
          created_at timestamptz NOT NULL
        );

        CREATE UNIQUE INDEX index_test_attribute_reviewers_table_unique
          ON _test_attribute_reviewers_table
          USING btree (test_attribute_id, test_reviewer_id);
    SQL
  end

  after(:context) do
    ApplicationRecord.connection.execute(<<~SQL)
        DROP TABLE _test_attribute_table;
        DROP TABLE _test_attribute_reviewers_table;
        DROP TABLE _test_reviewers_table;
    SQL
  end

  describe 'resetting on union errors' do
    let(:expected_error_message) { /must have the same number of columns/ }

    def load_query
      scopes = [
        TestAttribute.select('*'),
        TestAttribute.select(TestAttribute.column_names.join(','))
      ]

      TestAttribute.from_union(scopes).load
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

        TestAttribute.reset_column_information
      end

      it 'resets column information when encountering an UNION error' do
        expect do
          load_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
          .and change { TestAttribute.column_names }
            .from(%w[id created_at]).to(%w[id created_at _test_new_column])

        # Subsequent query load from new schema cache, so no more error
        expect do
          load_query
        end.not_to raise_error
      end

      it 'logs when column is reset' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error)
          .with(hash_including("extra.reset_model_name" => "TestAttribute"))
          .and_call_original

        expect do
          load_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end
    end

    context 'with mismatched columns due to coding error' do
      def load_mismatched_query
        scopes = [
          TestAttribute.select("id"),
          TestAttribute.select("id, created_at")
        ]

        TestAttribute.from_union(scopes).load
      end

      it 'limits reset_column_information calls' do
        expect(TestAttribute).to receive(:reset_column_information).and_call_original

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)

        expect(TestAttribute).not_to receive(:reset_column_information)

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end

      it 'does reset_column_information after some time has passed' do
        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)

        travel_to(described_class::MAX_RESET_PERIOD.from_now + 1.minute)
        expect(TestAttribute).to receive(:reset_column_information).and_call_original

        expect do
          load_mismatched_query
        end.to raise_error(ActiveRecord::StatementInvalid, expected_error_message)
      end
    end

    it 'handles ActiveRecord::StatementInvalid on the instance level' do
      t = TestAttribute.create!
      reviewer = TestReviewer.create!

      expect do
        t.assign_attributes(reviewer_ids: [reviewer.id, reviewer.id])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'resetting on missing column error on save' do
    let(:expected_error_message) { /unknown attribute '_test_new_column'/ }

    context 'with mismatched columns due to schema cache' do
      let!(:attrs) { TestAttribute.new.attributes }

      def initialize_with_new_column
        TestAttribute.new(attrs.merge(_test_new_column: 123))
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

        TestAttribute.reset_column_information
      end

      it 'resets column information when encountering an UnknownAttributeError' do
        expect do
          initialize_with_new_column
        end.to raise_error(ActiveModel::UnknownAttributeError, expected_error_message)
              .and change { TestAttribute.column_names }
                 .from(%w[id created_at]).to(%w[id created_at _test_new_column])

        # Subsequent query load from new schema cache, so no more error
        expect do
          initialize_with_new_column
        end.not_to raise_error
      end

      it 'logs when column is reset' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error)
          .with(hash_including("extra.reset_model_name" => "TestAttribute"))
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
             .and not_change { TestAttribute.column_names }
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationRecord do
  describe '#id_in' do
    let(:records) { create_list(:user, 3) }

    it 'returns records of the ids', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448906' do
      expect(User.id_in(records.last(2).map(&:id))).to eq(records.last(2))
    end
  end

  describe '.safe_ensure_unique' do
    let(:model) { build(:suggestion) }
    let_it_be(:note) { create(:diff_note_on_merge_request) }

    let(:klass) { model.class }

    before do
      allow(model).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
    end

    it 'returns false when ActiveRecord::RecordNotUnique is raised' do
      expect(model).to receive(:save!).once
      model.note_id = note.id
      expect(klass.safe_ensure_unique { model.save! }).to be_falsey
    end

    it 'retries based on retry count specified' do
      expect(model).to receive(:save!).exactly(3).times
      model.note_id = note.id
      expect(klass.safe_ensure_unique(retries: 2) { model.save! }).to be_falsey
    end
  end

  context 'safe find or create methods' do
    let_it_be(:note) { create(:diff_note_on_merge_request) }

    let(:suggestion_attributes) { attributes_for(:suggestion).merge!(note_id: note.id) }

    describe '.safe_find_or_create_by' do
      it 'creates the suggestion avoiding race conditions' do
        existing_suggestion = double(:Suggestion)

        expect(Suggestion).to receive(:find_by).and_return(nil, existing_suggestion)
        expect(Suggestion).to receive(:create).and_raise(ActiveRecord::RecordNotUnique)

        expect(Suggestion.safe_find_or_create_by(suggestion_attributes)).to eq(existing_suggestion)
      end

      it 'passes a block to find_or_create_by' do
        expect do |block|
          Suggestion.safe_find_or_create_by(suggestion_attributes, &block)
        end.to yield_with_args(an_object_having_attributes(suggestion_attributes))
      end

      it 'does not create a record when is not valid' do
        raw_usage_data = RawUsageData.safe_find_or_create_by({ recorded_at: nil })

        expect(raw_usage_data.id).to be_nil
        expect(raw_usage_data).not_to be_valid
      end
    end

    describe '.safe_find_or_create_by!' do
      it 'creates a record using safe_find_or_create_by' do
        expect(Suggestion.safe_find_or_create_by!(suggestion_attributes))
          .to be_a(Suggestion)
      end

      it 'raises a validation error if the record was not persisted' do
        expect { Suggestion.safe_find_or_create_by!(note: nil) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'passes a block to find_or_create_by' do
        expect do |block|
          Suggestion.safe_find_or_create_by!(suggestion_attributes, &block)
        end.to yield_with_args(an_object_having_attributes(suggestion_attributes))
      end

      it 'raises a record not found error in case of attributes mismatch' do
        suggestion = Suggestion.safe_find_or_create_by!(suggestion_attributes)
        attributes = suggestion_attributes.merge(outdated: !suggestion.outdated)

        expect { Suggestion.safe_find_or_create_by!(attributes) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.underscore' do
    it 'returns the underscored value of the class as a string' do
      expect(MergeRequest.underscore).to eq('merge_request')
    end
  end

  describe '.where_exists' do
    it 'produces a WHERE EXISTS query' do
      user = create(:user)

      expect(User.where_exists(User.limit(1))).to eq([user])
    end
  end

  describe '.where_not_exists' do
    it 'produces a WHERE NOT EXISTS query' do
      create(:user, :two_factor_via_webauthn)
      user_2 = create(:user)

      expect(
        User.where_not_exists(
          WebauthnRegistration.where(WebauthnRegistration.arel_table[:user_id].eq(User.arel_table[:id])))
      ).to match_array([user_2])
    end
  end

  describe '.transaction', :delete do
    it 'opens a new transaction' do
      expect(described_class.connection.transaction_open?).to be false

      Project.transaction do
        expect(Project.connection.transaction_open?).to be true

        Project.transaction(requires_new: true) do
          expect(Project.connection.transaction_open?).to be true
        end
      end
    end

    it 'does not increment a counter when a transaction is not nested' do
      expect(described_class.connection.transaction_open?).to be false

      expect(::Gitlab::Database::Metrics)
        .not_to receive(:subtransactions_increment)

      Project.transaction do
        expect(Project.connection.transaction_open?).to be true
      end

      Project.transaction(requires_new: true) do
        expect(Project.connection.transaction_open?).to be true
      end
    end

    it 'increments a counter when a nested transaction is created' do
      expect(described_class.connection.transaction_open?).to be false

      expect(::Gitlab::Database::Metrics)
        .to receive(:subtransactions_increment)
        .with('Project')
        .once

      Project.transaction do
        Project.transaction(requires_new: true) do
          expect(Project.connection.transaction_open?).to be true
        end
      end
    end

    it 'increments a counter when a transaction is created in ActiveRecord' do
      expect(described_class.connection.transaction_open?).to be false

      expect(::Gitlab::Database::Metrics)
        .to receive(:subtransactions_increment)
        .with('ApplicationRecord')
        .once

      ApplicationRecord.transaction do
        ApplicationRecord.transaction(requires_new: true) do
          expect(ApplicationRecord.connection.transaction_open?).to be true
        end
      end
    end
  end

  describe '.with_fast_read_statement_timeout' do
    context 'when the query runs faster than configured timeout' do
      it 'executes the query without error' do
        result = nil

        expect do
          described_class.with_fast_read_statement_timeout(100) do
            result = described_class.connection.exec_query('SELECT 1')
          end
        end.not_to raise_error

        expect(result).not_to be_nil
      end
    end

    # This query hangs for 10ms and then gets cancelled.  As there is no
    # other way to test the timeout for sure, 10ms of waiting seems to be
    # reasonable!
    context 'when the query runs longer than configured timeout' do
      it 'cancels the query and raises an exception' do
        expect do
          described_class.with_fast_read_statement_timeout(10) do
            described_class.connection.exec_query('SELECT pg_sleep(0.1)')
          end
        end.to raise_error(ActiveRecord::QueryCanceled)
      end
    end

    context 'with database load balancing' do
      let(:session) { Gitlab::Database::LoadBalancing::Session.new }

      before do
        allow(::Gitlab::Database::LoadBalancing::SessionMap)
          .to receive(:current).with(described_class.load_balancer).and_return(session)
        allow(session).to receive(:fallback_to_replicas_for_ambiguous_queries).and_yield
      end

      it 'yields control' do
        expect do |blk|
          described_class.with_fast_read_statement_timeout(&blk)
        end.to yield_control.once
      end

      context 'when the query runs faster than configured timeout' do
        it 'executes the query without error' do
          result = nil

          expect do
            described_class.with_fast_read_statement_timeout(100) do
              result = described_class.connection.exec_query('SELECT 1')
            end
          end.not_to raise_error

          expect(result).not_to be_nil
        end
      end

      # This query hangs for 10ms and then gets cancelled.  As there is no
      # other way to test the timeout for sure, 10ms of waiting seems to be
      # reasonable!
      context 'when the query runs longer than configured timeout' do
        it 'cancels the query and raiss an exception' do
          expect do
            described_class.with_fast_read_statement_timeout(10) do
              described_class.connection.exec_query('SELECT pg_sleep(0.1)')
            end
          end.to raise_error(ActiveRecord::QueryCanceled)
        end
      end
    end
  end

  describe '.nullable_column?' do
    subject { Project.nullable_column?(attribute) }

    context 'when the column is defined as NOT NULL' do
      let(:attribute) { 'id' }

      it { is_expected.to be_falsey }
    end

    context 'when the column is not defined as NOT NULL' do
      let(:attribute) { 'name' }

      before do
        Project.clear_constraints_cache!
      end

      context 'when there is no check constraint' do
        it { is_expected.to be_truthy }
      end

      context 'when there is an `IS NOT NULL` check constraint' do
        context 'when the constraint is not valid' do
          before do
            Project.connection.execute(<<~SQL)
              ALTER TABLE projects
              ADD CONSTRAINT test_constraint CHECK (name is not null) not valid;
            SQL
          end

          it { is_expected.to be_truthy }
        end

        context 'when the constraint is valid' do
          before do
            Project.connection.execute(<<~SQL)
              ALTER TABLE projects
              ADD CONSTRAINT test_constraint CHECK (name is not null);
            SQL
          end

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '.default_select_columns' do
    shared_examples_for 'selects identically to the default' do
      it 'generates the same sql as the default' do
        expected_sql = test_model.all.to_sql
        generated_sql = test_model.all.select(test_model.default_select_columns).to_sql

        expect(expected_sql).to eq(generated_sql)
      end
    end

    before do
      described_class.connection.execute(<<~SQL)
        create table _test_tests (
          id bigserial primary key not null,
          ignore_me text
        )
      SQL
    end

    context 'without an ignored column' do
      let(:test_model) do
        Class.new(ApplicationRecord) do
          self.table_name = :_test_tests
        end
      end

      it_behaves_like 'selects identically to the default'
    end

    context 'with an ignored column' do
      let(:test_model) do
        Class.new(ApplicationRecord) do
          self.table_name = :_test_tests

          ignore_columns :ignore_me, remove_after: '2100-01-01', remove_with: '99.12'
        end
      end

      it_behaves_like 'selects identically to the default'
    end
  end
end

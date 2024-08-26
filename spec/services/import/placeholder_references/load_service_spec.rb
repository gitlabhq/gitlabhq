# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderReferences::LoadService, feature_category: :importers do
  let(:import_source) { Import::SOURCE_DIRECT_TRANSFER }
  let(:import_uid) { 1 }

  describe '#execute', :aggregate_failures, :clean_gitlab_redis_shared_state do
    let_it_be(:source_user) { create(:import_source_user) }
    let_it_be(:valid_reference) do
      {
        composite_key: nil,
        numeric_key: 1,
        model: 'Foo',
        namespace_id: source_user.namespace_id,
        source_user_id: source_user.id,
        user_reference_column: 'user_id',
        alias_version: 1
      }
    end

    let(:valid_reference_2) { valid_reference.merge(model: 'Bar') }
    let(:valid_reference_3) { valid_reference.merge(model: 'Baz') }

    subject(:result) { described_class.new(import_source: import_source, import_uid: import_uid).execute }

    it 'loads data pushed with `Import::PlaceholderReferences::PushService`' do
      record = create(:note)

      Import::PlaceholderReferences::PushService.from_record(
        import_source: import_source,
        import_uid: import_uid,
        source_user: source_user,
        record: record,
        user_reference_column: :author_id
      ).execute

      expect(Import::SourceUserPlaceholderReference)
        .to receive(:bulk_insert!)
        .with(kind_of(Array))
        .and_call_original

      expect_log_message(:info, message: 'Processing placeholder references')
      expect_log_message(:info, message: 'Processed placeholder references', processed_count: 1, error_count: 0)
      expect(result).to be_success
      expect(result.payload).to eq(processed_count: 1, error_count: 0)
      expect(Import::SourceUserPlaceholderReference.all).to contain_exactly(
        have_attributes(
          composite_key: nil,
          numeric_key: record.id,
          model: record.class.name,
          namespace_id: source_user.namespace_id,
          source_user_id: source_user.id,
          user_reference_column: 'author_id'
        )
      )
      expect(set_members_count).to eq(0)
    end

    it 'loads data to PostgreSQL in batches' do
      push(valid_reference)
      push(valid_reference_2)
      push(valid_reference_3)

      stub_const("#{described_class}::BATCH_LIMIT", 2)

      expect(Import::SourceUserPlaceholderReference)
        .to receive(:bulk_insert!)
        .with(kind_of(Array))
        .twice
        .and_call_original
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:limited_values_from_set)
        .twice
        .and_call_original
      expect_log_message(:info, message: 'Processing placeholder references')
      expect_log_message(:info, message: 'Processed placeholder references', processed_count: 3, error_count: 0)
      expect(result).to be_success
      expect(result.payload).to eq(processed_count: 3, error_count: 0)
      expect(Import::SourceUserPlaceholderReference.all).to contain_exactly(
        have_attributes(valid_reference),
        have_attributes(valid_reference_2),
        have_attributes(valid_reference_3)
      )
      expect(set_members_count).to eq(0)
    end

    it 'does not load data for another import_uid' do
      push(valid_reference)

      result = described_class.new(import_source: import_source, import_uid: 2).execute

      expect(result).to be_success
      expect(result.payload).to eq(processed_count: 0, error_count: 0)
      expect(Import::SourceUserPlaceholderReference.count).to eq(0)
      expect(set_members_count).to eq(1)
    end

    it 'does not load data for another import_source' do
      push(valid_reference)

      result = described_class.new(
        import_source: ::Import::SOURCE_PROJECT_EXPORT_IMPORT,
        import_uid: import_uid
      ).execute

      expect(result).to be_success
      expect(result.payload).to eq(processed_count: 0, error_count: 0)
      expect(Import::SourceUserPlaceholderReference.count).to eq(0)
      expect(set_members_count).to eq(1)
    end

    context 'when something in the batch has an unexpected schema' do
      let(:invalid_reference) { valid_reference.merge(foo: 'bar') }

      before do
        stub_const("#{described_class}::BATCH_LIMIT", 2)

        push(valid_reference)
        push(valid_reference_2)
        # We can't use `#push` because that validates,
        # so push directly to the set.
        store.add(invalid_reference.values.to_json)
        push(valid_reference_3)
      end

      it 'loads just the valid data, and clears the set' do
        expect_log_message(:error,
          message: 'Error processing placeholder reference',
          exception: {
            class: Import::SourceUserPlaceholderReference::SerializationError,
            message: 'Import::SourceUserPlaceholderReference::SerializationError'
          },
          item: invalid_reference.values.to_json
        )
        expect_log_message(:info, message: 'Processed placeholder references', processed_count: 4, error_count: 1)
        expect(result).to be_success
        expect(result.payload).to eq(processed_count: 4, error_count: 1)
        expect(Import::SourceUserPlaceholderReference.all).to contain_exactly(
          have_attributes(valid_reference),
          have_attributes(valid_reference_2),
          have_attributes(valid_reference_3)
        )
        expect(set_members_count).to eq(0)
      end
    end

    context 'when loading to PostgreSQL fails due to an ActiveRecord::RecordInvalid' do
      let(:invalid_reference) { valid_reference.except(:source_user_id) }

      before do
        stub_const("#{described_class}::BATCH_LIMIT", 2)

        push(invalid_reference)
        push(valid_reference)
        push(valid_reference_2)
        push(valid_reference_3)
      end

      it 'loads just the valid data, and clears the list' do
        expect_log_message(:error,
          message: 'Error processing placeholder reference',
          exception: {
            class: ActiveRecord::RecordInvalid,
            message: "Validation failed: Source user can't be blank"
          },
          item: hash_including(invalid_reference.stringify_keys)
        )
        expect(result).to be_success
        expect(result.payload).to eq(processed_count: 4, error_count: 1)
        expect(Import::SourceUserPlaceholderReference.all).to contain_exactly(
          have_attributes(valid_reference),
          have_attributes(valid_reference_2),
          have_attributes(valid_reference_3)
        )
        expect(set_members_count).to eq(0)
      end
    end

    context 'when loading to PostgreSQL fails due to ActiveRecord::InvalidForeignKey' do
      let(:invalid_reference) { valid_reference.merge(source_user_id: non_existing_record_id) }

      before do
        stub_const("#{described_class}::BATCH_LIMIT", 2)

        push(invalid_reference)
        push(valid_reference)
        push(valid_reference_2)
        push(valid_reference_3)
      end

      it 'logs the error and clears the failing batch but continues' do
        expect_log_message(:error,
          message: 'Error processing placeholder reference',
          exception: {
            class: ActiveRecord::InvalidForeignKey,
            message: include('PG::ForeignKeyViolation')
          },
          item: have_attributes(size: 2).and(include(have_attributes(invalid_reference)))
        )
        expect(result).to be_success
        expect(Import::SourceUserPlaceholderReference.count).to eq(2)
        expect(set_members_count).to eq(0)
      end
    end

    context 'when loading to PostgreSQL fails for an unhandled reason' do
      before do
        allow(Import::SourceUserPlaceholderReference)
          .to receive(:bulk_insert!)
          .and_raise(ActiveRecord::ConnectionTimeoutError)
      end

      it 'bubbles the exception and does not clear the set' do
        push(valid_reference)

        expect { result }.to raise_error(ActiveRecord::ConnectionTimeoutError)
        expect(Import::SourceUserPlaceholderReference.count).to eq(0)
        expect(set_members_count).to eq(1)
      end
    end

    context 'when fetching set from Redis fails' do
      before do
        allow(Gitlab::Cache::Import::Caching)
          .to receive(:limited_values_from_set)
          .and_raise(Redis::ConnectionError)
      end

      it 'bubbles the exception, does not load any data, and does not clear the set' do
        push(valid_reference)

        expect { result }.to raise_error(Redis::ConnectionError)
        expect(Import::SourceUserPlaceholderReference.count).to eq(0)
        expect(set_members_count).to eq(1)
      end
    end

    context 'when clearing the set from Redis fails' do
      before do
        allow(Gitlab::Cache::Import::Caching)
          .to receive(:set_remove)
          .and_raise(Redis::ConnectionError)
      end

      it 'bubbles the exception and does not clear the set, but does load the data' do
        push(valid_reference)

        expect { result }.to raise_error(Redis::ConnectionError)
        # (We tolerate that this leads to duplicate records loaded to PostgreSQL!)
        expect(Import::SourceUserPlaceholderReference.count).to eq(1)
        expect(set_members_count).to eq(1)
      end
    end

    def push(reference)
      serialized = Import::SourceUserPlaceholderReference.new(reference).to_serialized

      store.add(serialized)
    end

    def expect_log_message(type, **params)
      allow(Import::Framework::Logger).to receive(type)
      expect(Import::Framework::Logger).to receive(type)
        .with(params.merge(import_source: import_source, import_uid: import_uid))
    end

    def set_members_count
      store.count
    end

    def store
      Import::PlaceholderReferences::Store.new(
        import_source: import_source,
        import_uid: import_uid
      )
    end
  end
end

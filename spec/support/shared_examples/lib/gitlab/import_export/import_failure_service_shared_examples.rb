# frozen_string_literal: true

RSpec.shared_examples 'log import failure' do |importable_column|
  it 'tracks error' do
    extra = {
      source: action,
      relation_name: relation_key,
      relation_index: relation_index,
      retry_count: retry_count
    }
    extra[importable_column] = importable.id

    expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception, extra)

    subject.log_import_failure(
      source: action,
      relation_key: relation_key,
      relation_index: relation_index,
      exception: exception,
      retry_count: retry_count)
  end

  it 'saves data to ImportFailure' do
    log_import_failure

    import_failure = ImportFailure.last

    aggregate_failures do
      expect(import_failure[importable_column]).to eq(importable.id)
      expect(import_failure.source).to eq(action)
      expect(import_failure.relation_key).to eq(relation_key)
      expect(import_failure.relation_index).to eq(relation_index)
      expect(import_failure.exception_class).to eq('StandardError')
      expect(import_failure.exception_message).to eq(standard_error_message)
      expect(import_failure.correlation_id_value).to eq(correlation_id)
      expect(import_failure.retry_count).to eq(retry_count)
      expect(import_failure.external_identifiers).to eq("iid" => 1234)
    end
  end
end

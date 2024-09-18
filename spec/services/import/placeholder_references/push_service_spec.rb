# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderReferences::PushService, :aggregate_failures, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:import_source) { Import::SOURCE_DIRECT_TRANSFER }
  let(:import_uid) { 1 }

  shared_examples 'invalid reference' do |model, validation_error|
    it 'raises Import::PlaceholderReferences::InvalidReferenceError error' do
      expect { result }.to raise_error(
        Import::PlaceholderReferences::InvalidReferenceError, "Invalid placeholder user reference"
      )
    end

    context 'when in production environment' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      end

      it 'does not push data to Redis' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          an_instance_of(Import::PlaceholderReferences::InvalidReferenceError),
          model: model,
          errors: validation_error
        )

        expect(result).to be_error
        expect(result.message).to include(validation_error)
        expect(set).to be_empty
      end
    end
  end

  describe '#execute' do
    let(:composite_key) { nil }
    let(:numeric_key) { 9 }
    let(:model) { MergeRequest }

    subject(:result) do
      described_class.new(
        import_source: import_source,
        import_uid: import_uid,
        source_user_id: 123,
        source_user_namespace_id: 234,
        model: model,
        user_reference_column: 'author_id',
        numeric_key: numeric_key,
        composite_key: composite_key
      ).execute
    end

    it 'pushes data to Redis' do
      expected_result = [nil, 'MergeRequest', 234, 9, 123, 'author_id', 1].to_json

      expect(result).to be_success
      expect(result.payload).to eq(serialized_reference: expected_result)
      expect(set).to contain_exactly(expected_result)
    end

    it 'sets the alias_version value from PlaceholderReferences::AliasResolver' do
      expected_result = [nil, 'MergeRequest', 234, 9, 123, 'author_id', 192].to_json
      allow(Import::PlaceholderReferences::AliasResolver)
        .to receive(:version_for_model).with('MergeRequest').and_return(192)

      expect(result).to be_success
      expect(result.payload).to eq(serialized_reference: expected_result)
    end

    context 'when composite_key is provided' do
      let(:numeric_key) { nil }
      let(:composite_key) { { 'foo' => 1 } }

      it 'pushes data to Redis containing the composite_key' do
        expected_result = [
          { 'foo' => 1 }, 'MergeRequest', 234, nil, 123, 'author_id', 1
        ].to_json

        expect(result).to be_success
        expect(result.payload).to eq(serialized_reference: expected_result)
        expect(set).to contain_exactly(expected_result)
      end
    end

    context 'when both numeric_key and composite_key are present' do
      let(:composite_key) { { 'foo' => 1 } }

      it_behaves_like 'invalid reference', 'MergeRequest', 'one of numeric_key or composite_key must be present'
    end

    context 'when numeric_key and composite_key are blank' do
      let(:numeric_key) { nil }

      it_behaves_like 'invalid reference', 'MergeRequest', 'one of numeric_key or composite_key must be present'
    end
  end

  describe '.from_record' do
    let_it_be(:source_user) { create(:import_source_user) }
    let_it_be(:record) { create(:merge_request) }

    subject(:result) do
      described_class.from_record(
        import_source: import_source,
        import_uid: import_uid,
        source_user: source_user,
        record: record,
        user_reference_column: 'author_id'
      ).execute
    end

    it 'pushes data to Redis' do
      expected_result = [
        nil, 'MergeRequest', source_user.namespace_id, record.id, source_user.id, 'author_id', 1
      ].to_json

      expect(result).to be_success
      expect(result.payload).to eq(serialized_reference: expected_result)
      expect(set).to contain_exactly(expected_result)
    end

    context 'when record is an IssueAssignee' do
      let(:record) { IssueAssignee.new(issue_id: 1, user_id: 2) }

      it 'pushes a composite key' do
        expected_result = [
          { issue_id: 1, user_id: 2 }, 'IssueAssignee', source_user.namespace_id, nil, source_user.id, 'author_id', 1
        ].to_json

        expect(result).to be_success
        expect(result.payload).to eq(serialized_reference: expected_result)
        expect(set).to contain_exactly(expected_result)
      end
    end

    # rubocop:disable RSpec/VerifiedDoubles -- Custom object
    context 'when record does not respond to :id' do
      let(:record) { double(:record) }

      before do
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:version_for_model).and_return(1)
      end

      it_behaves_like 'invalid reference', 'RSpec::Mocks::Double', 'one of numeric_key or composite_key must be present'
    end

    context 'when record id is a string' do
      let(:record) { double(:record, id: 'string') }

      before do
        allow(Import::PlaceholderReferences::AliasResolver).to receive(:version_for_model).and_return(1)
      end

      it_behaves_like 'invalid reference', 'RSpec::Mocks::Double', 'one of numeric_key or composite_key must be present'
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end

  def set
    Import::PlaceholderReferences::Store.new(
      import_source: import_source,
      import_uid: import_uid
    ).get
  end
end

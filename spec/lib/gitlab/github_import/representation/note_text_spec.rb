# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::NoteText do
  shared_examples 'a Note text data' do |match_record_type|
    it 'returns an instance of NoteText' do
      expect(representation).to be_an_instance_of(described_class)
    end

    it 'includes record DB id' do
      expect(representation.record_db_id).to eq 42
    end

    it 'includes record type' do
      expect(representation.record_type).to eq match_record_type
    end

    it 'includes note text' do
      expect(representation.text).to eq 'Some text here..'
    end
  end

  describe '.from_db_record' do
    context 'with Release' do
      let(:record) { build_stubbed(:release, id: 42, description: 'Some text here..') }

      it_behaves_like 'a Note text data', 'Release' do
        let(:representation) { described_class.from_db_record(record) }
      end
    end

    context 'with Issue' do
      let(:record) { build_stubbed(:issue, id: 42, description: 'Some text here..') }

      it_behaves_like 'a Note text data', 'Issue' do
        let(:representation) { described_class.from_db_record(record) }
      end
    end

    context 'with MergeRequest' do
      let(:record) { build_stubbed(:merge_request, id: 42, description: 'Some text here..') }

      it_behaves_like 'a Note text data', 'MergeRequest' do
        let(:representation) { described_class.from_db_record(record) }
      end
    end

    context 'with Note' do
      let(:record) { build_stubbed(:note, id: 42, note: 'Some text here..') }

      it_behaves_like 'a Note text data', 'Note' do
        let(:representation) { described_class.from_db_record(record) }
      end
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Note text data', 'Release' do
      let(:hash) do
        {
          'record_db_id' => 42,
          'record_type' => 'Release',
          'text' => 'Some text here..'
        }
      end

      let(:representation) { described_class.from_json_hash(hash) }
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      record_id = rand(100)
      representation = described_class.new(record_db_id: record_id, text: 'text')

      expect(representation.github_identifiers).to eq({ db_id: record_id })
    end
  end
end

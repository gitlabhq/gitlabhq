# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::NoteText, feature_category: :importers do
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
    let(:representation) { described_class.from_db_record(record) }

    context 'with Release' do
      let(:record) { build_stubbed(:release, id: 42, description: 'Some text here..', tag: 'v1.0') }

      it_behaves_like 'a Note text data', 'Release'

      it 'includes tag' do
        expect(representation.tag).to eq 'v1.0'
      end
    end

    context 'with Issue' do
      let(:record) { build_stubbed(:issue, id: 42, iid: 2, description: 'Some text here..') }

      it_behaves_like 'a Note text data', 'Issue'

      it 'includes noteable iid' do
        expect(representation.iid).to eq 2
      end
    end

    context 'with MergeRequest' do
      let(:record) { build_stubbed(:merge_request, id: 42, iid: 2, description: 'Some text here..') }

      it_behaves_like 'a Note text data', 'MergeRequest'

      it 'includes noteable iid' do
        expect(representation.iid).to eq 2
      end
    end

    context 'with Note' do
      let(:record) { build_stubbed(:note, id: 42, note: 'Some text here..', noteable_type: 'Issue') }

      it_behaves_like 'a Note text data', 'Note'

      it 'includes noteable type' do
        expect(representation.noteable_type).to eq 'Issue'
      end
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Note text data', 'Release' do
      let(:hash) do
        {
          'record_db_id' => 42,
          'record_type' => 'Release',
          'text' => 'Some text here..',
          'tag' => 'v1.0'
        }
      end

      let(:representation) { described_class.from_json_hash(hash) }
    end
  end

  describe '#github_identifiers' do
    let(:iid) { nil }
    let(:tag) { nil }
    let(:noteable_type) { nil }
    let(:hash) do
      {
        'record_db_id' => 42,
        'record_type' => record_type,
        'text' => 'Some text here..',
        'iid' => iid,
        'tag' => tag,
        'noteable_type' => noteable_type
      }
    end

    subject { described_class.from_json_hash(hash) }

    context 'with Release' do
      let(:record_type) { 'Release' }
      let(:tag) { 'v1.0' }

      it 'returns a hash with needed identifiers' do
        expect(subject.github_identifiers).to eq(
          {
            db_id: 42,
            tag: 'v1.0'
          }
        )
      end
    end

    context 'with Issue' do
      let(:record_type) { 'Issue' }
      let(:iid) { 2 }

      it 'returns a hash with needed identifiers' do
        expect(subject.github_identifiers).to eq(
          {
            db_id: 42,
            noteable_iid: 2
          }
        )
      end
    end

    context 'with Merge Request' do
      let(:record_type) { 'MergeRequest' }
      let(:iid) { 3 }

      it 'returns a hash with needed identifiers' do
        expect(subject.github_identifiers).to eq(
          {
            db_id: 42,
            noteable_iid: 3
          }
        )
      end
    end

    context 'with Note' do
      let(:record_type) { 'Note' }
      let(:noteable_type) { 'MergeRequest' }

      it 'returns a hash with needed identifiers' do
        expect(subject.github_identifiers).to eq(
          {
            db_id: 42,
            noteable_type: 'MergeRequest'
          }
        )
      end
    end
  end

  describe '#has_attachments?' do
    subject { described_class.new({ text: text }).has_attachments? }

    context 'when text has attachments' do
      let(:text) { 'See ![image](https://user-images.githubusercontent.com/1/uuid-1.png) for details' }

      it { is_expected.to eq(true) }
    end

    context 'when text does not have attachments' do
      let(:text) { 'Some text here'  }

      it { is_expected.to eq(false) }
    end
  end

  describe '#attachments' do
    subject { described_class.new({ text: text }).attachments }

    context 'when text has attachments' do
      let(:text) { 'See ![image](https://user-images.githubusercontent.com/1/uuid-1.png) for details' }

      it { is_expected.to contain_exactly(instance_of(Gitlab::GithubImport::Markdown::Attachment)) }
    end

    context 'when text does not have attachments' do
      let(:text) { 'Some text here'  }

      it { is_expected.to be_empty }
    end
  end
end

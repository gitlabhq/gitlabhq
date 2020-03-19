# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::JSON::LegacyReader::User do
  let(:relation_names) { [] }
  let(:legacy_reader) { described_class.new(tree_hash, relation_names) }

  describe '#valid?' do
    subject { legacy_reader.valid? }

    context 'tree_hash not present' do
      let(:tree_hash) { nil }

      it { is_expected.to be false }
    end

    context 'tree_hash presents' do
      let(:tree_hash) { { "issues": [] } }

      it { is_expected.to be true }
    end
  end
end

describe Gitlab::ImportExport::JSON::LegacyReader::File do
  let(:fixture) { 'spec/fixtures/lib/gitlab/import_export/light/project.json' }
  let(:project_tree) { JSON.parse(File.read(fixture)) }
  let(:relation_names) { [] }
  let(:legacy_reader) { described_class.new(path, relation_names) }

  describe '#valid?' do
    subject { legacy_reader.valid? }

    context 'given valid path' do
      let(:path) { fixture }

      it { is_expected.to be true }
    end

    context 'given invalid path' do
      let(:path) { 'spec/non-existing-folder/do-not-create-this-file.json' }

      it { is_expected.to be false }
    end
  end

  describe '#root_attributes' do
    let(:path) { fixture }

    subject { legacy_reader.root_attributes(excluded_attributes) }

    context 'No excluded attributes' do
      let(:excluded_attributes) { [] }
      let(:relation_names) { [] }

      it 'returns the whole tree from parsed JSON' do
        expect(subject).to eq(project_tree)
      end
    end

    context 'Some attributes are excluded' do
      let(:excluded_attributes) { %w[milestones labels issues services snippets] }
      let(:relation_names) { %w[import_type archived] }

      it 'returns hash without excluded attributes and relations' do
        expect(subject).not_to include('milestones', 'labels', 'issues', 'services', 'snippets', 'import_type', 'archived')
      end
    end
  end

  describe '#consume_relation' do
    let(:path) { fixture }
    let(:key) { 'description' }

    context 'block not given' do
      it 'returns value of the key' do
        expect(legacy_reader).to receive(:relations).and_return({ key => 'test value' })
        expect(legacy_reader.consume_relation(key)).to eq('test value')
      end
    end

    context 'key has been consumed' do
      before do
        legacy_reader.consume_relation(key)
      end

      it 'does not yield' do
        expect do |blk|
          legacy_reader.consume_relation(key, &blk)
        end.not_to yield_control
      end
    end

    context 'value is nil' do
      before do
        expect(legacy_reader).to receive(:relations).and_return({ key => nil })
      end

      it 'does not yield' do
        expect do |blk|
          legacy_reader.consume_relation(key, &blk)
        end.not_to yield_control
      end
    end

    context 'value is not array' do
      before do
        expect(legacy_reader).to receive(:relations).and_return({ key => 'value' })
      end

      it 'yield the value with index 0' do
        expect do |blk|
          legacy_reader.consume_relation(key, &blk)
        end.to yield_with_args('value', 0)
      end
    end

    context 'value is an array' do
      before do
        expect(legacy_reader).to receive(:relations).and_return({ key => %w[item1 item2 item3] })
      end

      it 'yield each array element with index' do
        expect do |blk|
          legacy_reader.consume_relation(key, &blk)
        end.to yield_successive_args(['item1', 0], ['item2', 1], ['item3', 2])
      end
    end
  end

  describe '#tree_hash' do
    let(:path) { fixture }

    subject { legacy_reader.send(:tree_hash) }

    it 'parses the JSON into the expected tree' do
      expect(subject).to eq(project_tree)
    end

    context 'invalid JSON' do
      let(:path) { 'spec/fixtures/lib/gitlab/import_export/invalid_json/project.json' }

      it 'raise Exception' do
        expect { subject }.to raise_exception(Gitlab::ImportExport::Error, 'Incorrect JSON format')
      end
    end
  end
end

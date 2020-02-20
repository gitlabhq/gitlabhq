# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeLoader do
  let(:fixture) { 'spec/fixtures/lib/gitlab/import_export/with_duplicates.json' }
  let(:project_tree) { JSON.parse(File.read(fixture)) }

  context 'without de-duplicating entries' do
    let(:parsed_tree) do
      subject.load(fixture)
    end

    it 'parses the JSON into the expected tree' do
      expect(parsed_tree).to eq(project_tree)
    end

    it 'does not de-duplicate entries' do
      expect(parsed_tree['duped_hash_with_id']).not_to be(parsed_tree['array'][0]['duped_hash_with_id'])
    end
  end

  context 'with de-duplicating entries' do
    let(:parsed_tree) do
      subject.load(fixture, dedup_entries: true)
    end

    it 'parses the JSON into the expected tree' do
      expect(parsed_tree).to eq(project_tree)
    end

    it 'de-duplicates equal values' do
      expect(parsed_tree['duped_hash_with_id']).to be(parsed_tree['array'][0]['duped_hash_with_id'])
      expect(parsed_tree['duped_hash_with_id']).to be(parsed_tree['nested']['duped_hash_with_id'])
      expect(parsed_tree['duped_array']).to be(parsed_tree['array'][1]['duped_array'])
      expect(parsed_tree['duped_array']).to be(parsed_tree['nested']['duped_array'])
    end

    it 'does not de-duplicate hashes without IDs' do
      expect(parsed_tree['duped_hash_no_id']).to eq(parsed_tree['array'][2]['duped_hash_no_id'])
      expect(parsed_tree['duped_hash_no_id']).not_to be(parsed_tree['array'][2]['duped_hash_no_id'])
    end

    it 'keeps single entries intact' do
      expect(parsed_tree['simple']).to eq(42)
      expect(parsed_tree['nested']['array']).to eq(["don't touch"])
    end
  end
end

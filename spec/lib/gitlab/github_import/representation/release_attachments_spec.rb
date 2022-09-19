# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ReleaseAttachments do
  shared_examples 'a Release attachments data' do
    it 'returns an instance of ReleaseAttachments' do
      expect(representation).to be_an_instance_of(described_class)
    end

    it 'includes release DB id' do
      expect(representation.release_db_id).to eq 42
    end

    it 'includes release description' do
      expect(representation.description).to eq 'Some text here..'
    end
  end

  describe '.from_db_record' do
    let(:release) { build_stubbed(:release, id: 42, description: 'Some text here..') }

    it_behaves_like 'a Release attachments data' do
      let(:representation) { described_class.from_db_record(release) }
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a Release attachments data' do
      let(:hash) do
        {
          'release_db_id' => 42,
          'description' => 'Some text here..'
        }
      end

      let(:representation) { described_class.from_json_hash(hash) }
    end
  end

  describe '#github_identifiers' do
    it 'returns a hash with needed identifiers' do
      release_id = rand(100)
      representation = described_class.new(release_db_id: release_id, description: 'text')

      expect(representation.github_identifiers).to eq({ db_id: release_id })
    end
  end
end

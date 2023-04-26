# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubFailureSerializer, feature_category: :importers do
  subject(:serializer) { described_class.new }

  it 'represents GithubFailureEntity entities' do
    expect(described_class.entity_class).to eq(Import::GithubFailureEntity)
  end

  describe '#represent' do
    let(:timestamp) { Time.new(2023, 1, 1).utc }
    let(:github_identifiers) { { 'iid' => 2, 'object_type' => 'pull_request', 'title' => 'Implement cool feature' } }
    let(:project) do
      instance_double(
        Project,
        id: 123456,
        import_status: 'finished',
        import_url: 'https://github.com/example/repo.git',
        import_source: 'example/repo'
      )
    end

    let(:import_failure) do
      instance_double(
        ImportFailure,
        project: project,
        exception_class: 'Some class',
        exception_message: 'Something went wrong',
        source: 'Gitlab::GithubImport::Importer::PullRequestImporter',
        correlation_id_value: '2ea9c4b8587b6df49f35a3fb703688aa',
        external_identifiers: github_identifiers,
        created_at: timestamp
      )
    end

    let(:expected_data) do
      {
        type: 'pull_request',
        title: 'Implement cool feature',
        provider_url: 'https://github.com/example/repo/pull/2',
        details: {
          exception_class: import_failure.exception_class,
          exception_message: import_failure.exception_message,
          correlation_id_value: import_failure.correlation_id_value,
          source: import_failure.source,
          github_identifiers: github_identifiers,
          created_at: timestamp.iso8601(3)
        }
      }.deep_stringify_keys
    end

    context 'when a single object is being serialized' do
      let(:resource) { import_failure }

      it 'serializes import failure' do
        expect(serializer.represent(resource).as_json).to eq expected_data
      end
    end

    context 'when multiple objects are being serialized' do
      let(:count) { 3 }
      let(:resource) { Array.new(count, import_failure) }

      it 'serializes array of import failures' do
        expect(serializer.represent(resource).as_json).to all(eq(expected_data))
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubRealtimeRepoSerializer, feature_category: :importers do
  subject(:serializer) { described_class.new }

  it '.entity_class' do
    expect(described_class.entity_class).to eq(Import::GithubRealtimeRepoEntity)
  end

  describe '#represent' do
    let(:import_state) { instance_double(ProjectImportState, failed?: false, completed?: false) }
    let(:project) do
      instance_double(
        Project,
        id: 100500,
        import_status: 'importing',
        import_state: import_state
      )
    end

    let(:expected_data) do
      {
        id: project.id,
        import_status: 'importing',
        stats: { fetched: {}, imported: {} }
      }.deep_stringify_keys
    end

    context 'when a single object is being serialized' do
      let(:resource) { project }

      it 'serializes organization object' do
        expect(serializer.represent(resource).as_json).to eq expected_data
      end
    end

    context 'when multiple objects are being serialized' do
      let(:count) { 3 }
      let(:resource) { Array.new(count, project) }

      it 'serializes array of organizations' do
        expect(serializer.represent(resource).as_json).to all(eq(expected_data))
      end
    end
  end
end

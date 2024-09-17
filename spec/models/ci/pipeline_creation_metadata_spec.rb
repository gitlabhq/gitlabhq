# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreationMetadata, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }

  let(:pipeline_creation_id) { SecureRandom.uuid }
  let(:redis_key) { "project:{#{project.full_path}}:ci_pipeline_creation:{#{pipeline_creation_id}}" }

  context 'when initialized with an ID' do
    it 'sets that ID as the pipeline creation ID' do
      pipeline_creation = described_class.new(id: pipeline_creation_id, project: project)

      expect(pipeline_creation.id).to eq(pipeline_creation_id)
    end
  end

  context 'when initialized without an ID' do
    it 'generates a UUID to use as the pipeline creation ID' do
      expect(SecureRandom).to receive(:uuid).once

      described_class.new(project: project)
    end
  end

  context 'when initialized with a status' do
    it 'sets that status as the pipeline creation status' do
      pipeline_creation = described_class.new(project: project, status: :succeeded)

      expect(pipeline_creation.status).to eq(:succeeded)
    end
  end

  context 'when initialized without a status' do
    it 'sets the pipeline creation status to creating' do
      pipeline_creation = described_class.new(project: project)

      expect(pipeline_creation.status).to eq(:creating)
    end
  end

  describe '.find', :use_clean_rails_redis_caching do
    before do
      Rails.cache.write(redis_key, { status: :creating, pipeline_id: nil })
    end

    it 'finds the status of the pipeline creation from Redis' do
      pipeline_creation = described_class.find(project: project, id: pipeline_creation_id)

      expect(pipeline_creation.status).to eq(:creating)
      expect(pipeline_creation.pipeline_id).to be_nil
      expect(pipeline_creation.id).to eq(pipeline_creation_id)
    end
  end
end

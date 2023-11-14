# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::UpdateMetadataService, feature_category: :continuous_integration do
  subject(:execute) { described_class.new(pipeline, { name: name }).execute }

  let(:name) { 'Some random pipeline name' }

  context 'when pipeline has no name' do
    let(:pipeline) { create(:ci_pipeline) }

    it 'updates the name' do
      expect { execute }.to change { pipeline.reload.name }.to(name)
    end
  end

  context 'when pipeline has a name' do
    let(:pipeline) { create(:ci_pipeline, name: 'Some other name') }

    it 'updates the name' do
      expect { execute }.to change { pipeline.reload.name }.to(name)
    end
  end

  context 'when new name is too long' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:name) { 'a' * 256 }

    it 'does not update the name' do
      expect { execute }.not_to change { pipeline.reload.name }
    end
  end
end

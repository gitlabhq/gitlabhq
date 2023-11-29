# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CreateModelVersionService, feature_category: :mlops do
  let(:model) { create(:ml_models) }
  let(:params) { {} }

  subject(:service) { described_class.new(model, params).execute }

  context 'when no versions exist' do
    it 'creates a model version', :aggregate_failures do
      expect { service }.to change { Ml::ModelVersion.count }.by(1).and change { Ml::Candidate.count }.by(1)
      expect(model.reload.latest_version.version).to eq('1.0.0')
    end
  end

  context 'when a version exist' do
    before do
      create(:ml_model_versions, model: model, version: '3.0.0')
    end

    it 'creates another model version and increments the version number', :aggregate_failures do
      expect { service }.to change { Ml::ModelVersion.count }.by(1).and change { Ml::Candidate.count }.by(1)
      expect(model.reload.latest_version.version).to eq('4.0.0')
    end
  end
end

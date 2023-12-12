# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::FindOrCreateModelVersionService, feature_category: :mlops do
  let_it_be(:existing_version) { create(:ml_model_versions) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:package) { nil }
  let(:description) { nil }

  let(:params) do
    {
      model_name: name,
      version: version,
      package: package,
      description: description,
      user: user
    }
  end

  subject(:model_version) { described_class.new(project, params).execute }

  describe '#execute' do
    context 'when model version exists' do
      let(:name) { existing_version.name }
      let(:version) { existing_version.version }
      let(:project) { existing_version.project }

      it 'returns existing model version', :aggregate_failures do
        expect { model_version }.to change { Ml::ModelVersion.count }.by(0)
        expect { model_version }.to change { Ml::Candidate.count }.by(0)
        expect(model_version).to eq(existing_version)
      end
    end

    context 'when model does not exist' do
      let(:project) { existing_version.project }
      let(:name) { 'a_new_model' }
      let(:version) { '2.0.0' }

      it 'does not create a new model version', :aggregate_failures do
        expect { model_version }.to change { Ml::ModelVersion.count }.by(0)
      end
    end

    context 'when model exists and model version does not' do
      let(:project) { existing_version.project }
      let(:name) { existing_version.name }
      let(:version) { '2.0.0' }
      let(:description) { 'A model version' }

      let(:package) { create(:ml_model_package, project: project, name: name, version: version) }

      it 'creates a new model version', :aggregate_failures do
        expect { model_version }.to change { Ml::ModelVersion.count }.by(1)

        expect(model_version.version).to eq(version)
        expect(model_version.model).to eq(existing_version.model)
        expect(model_version.description).to eq(description)
      end
    end
  end
end

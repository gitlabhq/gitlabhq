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

  context 'when a version is created' do
    it 'creates a package' do
      expect { service }.to change { Ml::ModelVersion.count }.by(1).and change {
                                                                          Packages::MlModel::Package.count
                                                                        }.by(1)
      expect(model.reload.latest_version.package.name).to eq(model.name)
      expect(model.latest_version.package.version).to eq(model.latest_version.version)
    end
  end

  context 'when a version is created and the package already exists' do
    it 'does not creates a package' do
      next_version = Ml::IncrementVersionService.new(model.latest_version.try(:version)).execute
      create(:ml_model_package, name: model.name, version: next_version, project: model.project)

      expect { service }.to change { Ml::ModelVersion.count }.by(1).and not_change {
                                                                          Packages::MlModel::Package.count
                                                                        }
      expect(model.reload.latest_version.package.name).to eq(model.name)
      expect(model.latest_version.package.version).to eq(model.latest_version.version)
    end
  end

  context 'when a version is created and an existing package supplied' do
    it 'does not creates a package' do
      next_version = Ml::IncrementVersionService.new(model.latest_version.try(:version)).execute
      package = create(:ml_model_package, name: model.name, version: next_version, project: model.project)
      service = described_class.new(model, { package: package })

      expect { service.execute }.to change { Ml::ModelVersion.count }.by(1).and not_change {
                                                                                  Packages::MlModel::Package.count
                                                                                }
      expect(model.reload.latest_version.package.name).to eq(model.name)
      expect(model.latest_version.package.version).to eq(model.latest_version.version)
    end
  end
end

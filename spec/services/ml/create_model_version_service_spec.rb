# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CreateModelVersionService, feature_category: :mlops do
  let(:model) { create(:ml_models) }
  let(:service) { described_class.new(model, params).execute }
  let(:params) { {} }

  before do
    allow(Gitlab::InternalEvents).to receive(:track_event)
  end

  subject(:model_version) { service.payload[:model_version] }

  context 'when no versions exist and no value is passed for version' do
    it 'creates a model version', :aggregate_failures do
      expect { service }.to change { Ml::ModelVersion.count }.by(1)
                                                             .and change { Ml::Candidate.count }.by(1)
                                                             .and change { Packages::MlModel::Package.count }.by(1)

      expect(model.reload.latest_version.version).to eq('1.0.0')
      expect(service).to be_success

      expect(model.latest_version.package.name).to eq(model.name)
      expect(model.latest_version.package.version).to eq('1.0.0')

      expect(Gitlab::InternalEvents).to have_received(:track_event).with(
        'model_registry_ml_model_version_created',
        { project: model.project, user: nil }
      )
    end
  end

  context 'when a version exist and no value is passed for version' do
    before do
      create(:ml_model_versions, model: model, version: '3.0.0')
    end

    it 'creates another model version and increments the version number', :aggregate_failures do
      expect { service }.to change { Ml::ModelVersion.count }.by(1).and change { Ml::Candidate.count }.by(1)
      expect(model.reload.latest_version.version).to eq('4.0.0')
      expect(service).to be_success

      expect(Gitlab::InternalEvents).to have_received(:track_event).with(
        'model_registry_ml_model_version_created',
        { project: model.project, user: nil }
      )
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
      expect(service).to be_success
    end
  end

  context 'when creation of a model_version fails' do
    it 'returns error' do
      allow_next_instance_of(::Ml::ModelVersion) do |model_version|
        allow(model_version).to receive(:save).and_return(false)
        errors = ActiveModel::Errors.new(model_version).tap { |e| e.add(:id, 'some error') }
        allow(model_version).to receive(:errors).and_return(errors)
      end

      expect { service }.to not_change { Ml::ModelVersion.count }.and not_change { Packages::MlModel::Package.count }
      expect(service).to be_error
      expect(service.message).to include('Id some error')
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

    context 'when metadata are supplied, add them as metadata' do
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: 'key2', value: 'value2' }] }
      let(:params) { { metadata: metadata } }

      it 'creates metadata records', :aggregate_failures do
        expect { service }.to change { Ml::ModelVersion.count }.by(1)

        expect(model_version.metadata.count).to eq 2
      end
    end

    # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
    context 'for metadata with duplicate keys, it does not create duplicate records' do
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: 'key1', value: 'value2' }] }
      let(:params) { { metadata: metadata } }

      it 'raises an error', :aggregate_failures do
        expect(service).to be_error
        expect(service.message).to include("Validation failed: Name 'key1' already taken")
      end
    end

    # # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
    context 'for metadata with invalid keys, it does not create invalid records' do
      let(:metadata) { [{ key: 'key1', value: 'value1' }, { key: '', value: 'value2' }] }
      let(:params) { { metadata: metadata } }

      it 'raises an error', :aggregate_failures do
        expect(service).to be_error
        expect(service.message).to include("Validation failed: Name can't be blank")
      end
    end
  end

  context 'when a version string is supplied during creation' do
    let(:params) { { version: '1.2.3' } }

    it 'creates a package' do
      expect { service }.to change { Ml::ModelVersion.count }.by(1).and change {
                                                                          Packages::MlModel::Package.count
                                                                        }.by(1)
      expect(model.reload.latest_version.version).to eq('1.2.3')
      expect(model.latest_version.package.version).to eq('1.2.3')
    end
  end

  context 'when version string supplied is invalid' do
    let(:params) { { version: 'invalid-version' } }

    it 'returns error' do
      expect { service }.to not_change { Ml::ModelVersion.count }.and not_change { Packages::MlModel::Package.count }
      expect(service).to be_error
      expect(model_version).to be_nil
      expect(service.message).to include('Version must be semantic version')
    end
  end
end

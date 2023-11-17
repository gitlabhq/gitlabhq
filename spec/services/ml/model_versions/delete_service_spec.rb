# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersions::DeleteService, feature_category: :mlops do
  let_it_be(:valid_model_version) do
    create(:ml_model_versions, :with_package)
  end

  let(:project) { valid_model_version.project }
  let(:user) { valid_model_version.project.owner }
  let(:name) { valid_model_version.name }
  let(:version) { valid_model_version.version }

  subject(:execute_service) { described_class.new(project, name, version, user).execute }

  describe '#execute' do
    context 'when model version exists' do
      it 'deletes the model version', :aggregate_failures do
        expect(execute_service).to be_success
        expect(Ml::ModelVersion.find_by(id: valid_model_version.id)).to be_nil
      end
    end

    context 'when model version does not exist' do
      let(:version) { 'wrong-version' }

      it { is_expected.to be_error.and have_attributes(message: 'Model not found') }
    end

    context 'when model version has no package' do
      before do
        valid_model_version.update!(package: nil)
      end

      it 'does not trigger destroy package service', :aggregate_failures do
        expect(Packages::MarkPackageForDestructionService).not_to receive(:new)
        expect(execute_service).to be_success
      end
    end

    context 'when package cannot be marked for destruction' do
      before do
        allow_next_instance_of(Packages::MarkPackageForDestructionService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end
      end

      it 'does not delete the model version', :aggregate_failures do
        is_expected.to be_error.and have_attributes(message: 'error')
        expect(Ml::ModelVersion.find_by(id: valid_model_version.id)).to eq(valid_model_version)
      end
    end
  end
end

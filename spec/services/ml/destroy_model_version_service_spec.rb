# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::DestroyModelVersionService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:model) { create(:ml_models, project: project) }

  let(:user) { project.owner }

  subject(:execute_service) { described_class.new(model_version, user).execute }

  describe '#execute' do
    context 'when model version exists' do
      let(:model_version) { create(:ml_model_versions, :with_package, model: model) }

      it 'deletes the model version', :aggregate_failures do
        expect(execute_service).to be_success
        expect(execute_service.payload[:model_version]).to eq(model_version)
        expect(Ml::ModelVersion.find_by(id: model_version.id)).to be_nil
      end
    end

    context 'when model version has no package' do
      let(:model_version) { create(:ml_model_versions, model: model) }

      it 'does not trigger destroy package service', :aggregate_failures do
        expect(Packages::MarkPackageForDestructionService).not_to receive(:new)
        expect(execute_service).to be_success
      end
    end

    context 'when package cannot be marked for destruction' do
      let(:model_version) { create(:ml_model_versions, :with_package, model: model) }
      let(:user) { nil }

      it 'does not delete the model version', :aggregate_failures do
        is_expected.to be_error.and have_attributes(message: "You don't have access to this package")
        expect(Ml::ModelVersion.find_by(id: model_version.id)).to eq(model_version)
      end
    end
  end
end

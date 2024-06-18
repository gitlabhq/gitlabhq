# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::DestroyModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:model0) { create(:ml_models, :with_latest_version_and_package) }
  let_it_be(:model1) { create(:ml_models, :with_latest_version_and_package) }

  let(:model) { model0 }
  let(:service) { described_class.new(model, user) }

  describe '#execute' do
    subject(:service_result) { service.execute }

    context 'when model fails to delete' do
      it 'returns nil' do
        allow(model).to receive(:destroy).and_return(false)

        expect(service_result).to be_error
      end
    end

    context 'when a model exists' do
      it 'destroys the model', :aggregate_failures do
        allow_next_instance_of(Packages::MarkPackagesForDestructionService) do |instance|
          allow(instance).to receive(:execute).and_return ServiceResponse.success(message: "")
        end

        expect { service_result }.to change { Ml::Model.count }.by(-1).and change { Ml::ModelVersion.count }.by(-1)
        expect(service_result).to be_success
      end

      context 'when a package cannot be marked for destruction' do
        let(:model) { model1 }

        before do
          allow_next_instance_of(Packages::MarkPackagesForDestructionService) do |instance|
            allow(instance).to receive(:execute).and_return ServiceResponse.error(message: "An error")
          end
        end

        it 'returns success with warning', :aggregate_failures do
          expect { service_result }.not_to change { Ml::Model.count }
          expect(service_result).to be_error
          expect(service_result.message).to eq("An error")
        end
      end
    end
  end
end

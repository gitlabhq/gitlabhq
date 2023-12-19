# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::DestroyModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:model) { create(:ml_models, :with_latest_version_and_package) }
  let(:service) { described_class.new(model, user) }

  describe '#execute' do
    context 'when model name does not exist in the project' do
      it 'returns nil' do
        allow(model).to receive(:destroy).and_return(false)
        expect(service.execute).to be nil
      end
    end

    context 'when a model exists' do
      it 'destroys the model' do
        expect(Packages::MarkPackagesForDestructionService).to receive(:new).with(packages: model.all_packages,
          current_user: user).and_return(instance_double('Packages::MarkPackagesForDestructionService').tap do |service|
                                           expect(service).to receive(:execute)
                                         end)
        expect { service.execute }.to change { Ml::Model.count }.by(-1).and change { Ml::ModelVersion.count }.by(-1)
      end
    end
  end
end

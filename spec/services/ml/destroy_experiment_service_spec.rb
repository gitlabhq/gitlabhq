# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::DestroyExperimentService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:model) { create(:ml_models, project: project) }

  let(:experiment) { create(:ml_experiments, project: project) }
  let(:experiment_with_model) { create(:ml_experiments, project: project, model_id: model.id) }
  let(:service) { described_class.new(experiment) }

  describe '#execute' do
    subject(:destroy_result) { service.execute }

    context 'when experiment is successfully destroyed' do
      it 'returns a success response' do
        expect(destroy_result).to be_success
      end

      it 'destroys the experiment' do
        expect(destroy_result).to be_success
        expect(destroy_result.payload[:experiment]).to eq(experiment)
        expect(Ml::Experiment.find_by(id: experiment.id)).to be_nil
      end
    end

    context 'when experiment fails to destroy' do
      before do
        allow(experiment).to receive(:destroy).and_return(false)
      end

      it 'returns an error response' do
        expect(destroy_result).to be_error
      end
    end

    context 'when experiment is associated with a model' do
      let(:experiment) { experiment_with_model }

      it 'returns an error response' do
        expect(destroy_result).to be_error
        expect(destroy_result.message[0]).to eq('Cannot delete an experiment associated to a model')
      end

      it 'does not destroy the experiment' do
        expect(Ml::Experiment.find_by(id: experiment.id)).to eq(experiment)
      end
    end
  end
end

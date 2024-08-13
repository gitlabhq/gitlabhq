# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::FindModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:existing_model) { create(:ml_models) }
  let(:finder) { described_class.new(project, name, model_id) }
  let(:model_id) { nil }

  describe '#execute' do
    context 'when model_id is provided' do
      let(:project) { existing_model.project }
      let(:name) { nil }
      let(:model_id) { existing_model.id }

      it 'returns the model with the given model_id' do
        expect(finder.execute).to eq(existing_model)
      end

      context 'when model_id does not exist' do
        let(:model_id) { non_existing_record_id }

        it 'returns nil' do
          expect(finder.execute).to be_nil
        end
      end
    end

    context 'when neither model_id nor name is provided' do
      let(:project) { existing_model.project }
      let(:name) { nil }

      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end

    context 'when model_id is not provided' do
      context 'when model name does not exist in the project' do
        let(:name) { 'new_model' }
        let(:project) { existing_model.project }

        it 'returns nil' do
          expect(finder.execute).to be_nil
        end
      end

      context 'when model with name exists' do
        let(:name) { existing_model.name }
        let(:project) { existing_model.project }

        it 'returns the existing model' do
          expect(finder.execute).to eq(existing_model)
        end
      end
    end
  end
end

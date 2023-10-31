# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::FindModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:existing_model) { create(:ml_models) }
  let(:finder) { described_class.new(project, name) }

  describe '#execute' do
    context 'when model name does not exist in the project' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }

      it 'reutrns nil' do
        expect(finder.execute).to be nil
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

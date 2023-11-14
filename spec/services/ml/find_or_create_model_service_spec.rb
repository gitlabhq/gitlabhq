# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::FindOrCreateModelService, feature_category: :mlops do
  let_it_be(:user) { create(:user) }
  let_it_be(:existing_model) { create(:ml_models) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:description) { 'description' }
  let_it_be(:metadata) { [] }

  subject(:create_model) { described_class.new(project, name, user, description, metadata).execute }

  describe '#execute' do
    context 'when model name does not exist in the project' do
      let(:name) { 'new_model' }
      let(:project) { existing_model.project }

      it 'creates a model', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(1)

        expect(create_model.name).to eq(name)
      end
    end

    context 'when model name exists but project is different' do
      let(:name) { existing_model.name }
      let(:project) { another_project }

      it 'creates a model', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(1)

        expect(create_model.name).to eq(name)
      end
    end

    context 'when model with name exists' do
      let(:name) { existing_model.name }
      let(:project) { existing_model.project }

      it 'fetches existing model', :aggregate_failures do
        expect { create_model }.to change { Ml::Model.count }.by(0)

        expect(create_model).to eq(existing_model)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::UpdateModelService, feature_category: :mlops do
  let_it_be(:model) { create(:ml_models) }
  let_it_be(:description) { 'updated model description' }
  let(:service) { described_class.new(model, description) }

  describe '#execute' do
    context 'when supplied with a non-model object' do
      let(:model) { nil }

      it 'returns nil' do
        expect { service.execute }.to raise_error(NoMethodError)
      end
    end

    context 'with an existing model' do
      it 'updates the description' do
        updated = service.execute
        expect(updated.class).to be(Ml::Model)
        expect(updated.description).to eq(description)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::UpdateModelService, feature_category: :mlops do
  let_it_be(:model) { create(:ml_models) }
  let_it_be(:new_description) { 'updated model description' }
  let(:service) { described_class.new(model, new_description) }

  describe '#execute' do
    subject(:service_result) { service.execute }

    context 'when supplied with a non-model object' do
      let(:model) { nil }

      it 'returns an error' do
        expect(service_result).to be_error
      end
    end

    context 'with an existing model' do
      it 'description is initially blank' do
        expect(model.description).to eq(nil)
      end

      it 'updates the description' do
        expect(service_result.payload.description).to eq(new_description)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersionMetadata, feature_category: :mlops do
  describe 'associations' do
    it { is_expected.to belong_to(:model_version).required }
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:value).is_at_most(5000) }
  end

  describe 'validations' do
    let_it_be(:metadata) { create(:ml_model_version_metadata, name: 'some_metadata') }
    let_it_be(:model_version) { metadata.model_version }

    it 'is unique within the model version' do
      expect do
        model_version.metadata.create!(name: 'some_metadata', value: 'blah')
      end.to raise_error.with_message(/Name 'some_metadata' already taken/)
    end

    it 'a model version is required' do
      expect do
        described_class.create!(name: 'some_metadata', value: 'blah')
      end.to raise_error.with_message(/Model version must exist/)
    end
  end
end

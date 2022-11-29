# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ExperimentMetadata, feature_category: :mlops do
  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
  end

  describe 'uniqueness of name' do
    let_it_be(:metadata) { create(:ml_experiment_metadata, name: 'some_metadata') }
    let_it_be(:experiment) { metadata.experiment }

    it 'is unique within experiment' do
      expect do
        experiment.metadata.create!(name: 'some_metadata', value: 'blah')
      end.to raise_error.with_message(/Name 'some_metadata' already taken/)
    end
  end
end

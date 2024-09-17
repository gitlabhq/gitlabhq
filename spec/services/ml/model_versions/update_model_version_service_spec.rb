# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersions::UpdateModelVersionService, feature_category: :mlops do
  let_it_be(:existing_version) { create(:ml_model_versions) }

  let(:project) { existing_version.project }
  let(:name) { existing_version.name }
  let(:version) { existing_version.version }
  let(:description) { 'A model version description' }

  subject(:execute_service) { described_class.new(project, name, version, description).execute }

  describe '#execute' do
    context 'when model version exists' do
      it { is_expected.to be_success }

      it 'updates the model version description' do
        execute_service

        expect(execute_service.payload.description).to eq(description)
      end
    end

    context 'when description is invalid' do
      let(:description) { 'a' * 10001 }

      it { is_expected.to be_error }
    end

    context 'when model does not exist' do
      let(:name) { 'a_new_model' }

      it { is_expected.to be_error }
    end

    context 'when model version does not exist' do
      let(:name) { '2.0.0' }

      it { is_expected.to be_error }
    end
  end
end

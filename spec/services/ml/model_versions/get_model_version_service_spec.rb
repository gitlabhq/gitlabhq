# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersions::GetModelVersionService, feature_category: :mlops do
  let_it_be(:existing_version) { create(:ml_model_versions) }
  let_it_be(:another_project) { create(:project) }

  subject(:model_version) { described_class.new(project, name, version).execute }

  describe '#execute' do
    context 'when model version exists' do
      let(:name) { existing_version.name }
      let(:version) { existing_version.version }
      let(:project) { existing_version.project }

      it { is_expected.to eq(existing_version) }
    end

    context 'when model version does not exist' do
      let(:project) { existing_version.project }
      let(:name) { 'a_new_model' }
      let(:version) { '2.0.0' }

      it { is_expected.to be_nil }
    end
  end
end

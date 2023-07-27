# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelPresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model1) { build_stubbed(:ml_models, project: project) }
  let_it_be(:model2) { build_stubbed(:ml_models, :with_latest_version_and_package, project: project) }

  describe '#latest_version_name' do
    subject { model.present.latest_version_name }

    context 'when model has version' do
      let(:model) { model2 }

      it 'is the version of latest_version' do
        is_expected.to eq(model2.latest_version.version)
      end
    end

    context 'when model has no versions' do
      let(:model) { model1 }

      it { is_expected.to be_nil }
    end
  end

  describe '#latest_package_path' do
    subject { model.present.latest_package_path }

    context 'when model version does not have package' do
      let(:model) { model1 }

      it { is_expected.to be_nil }
    end

    context 'when latest model version has package' do
      let(:model) { model2 }

      it { is_expected.to eq("/#{project.full_path}/-/packages/#{model.latest_version.package_id}") }
    end
  end
end

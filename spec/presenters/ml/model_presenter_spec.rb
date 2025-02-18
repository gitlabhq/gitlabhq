# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelPresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model1) { build_stubbed(:ml_models, project: project) }
  let_it_be(:model2) { build_stubbed(:ml_models, :with_latest_version_and_package, project: project) }
  let_it_be(:model3) { build_stubbed(:ml_models, :with_versions, project: project) }

  let_it_be(:model4) { build_stubbed(:ml_models, project: project) }

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

  describe '#version_count' do
    subject { model3.present.version_count }

    it { is_expected.to eq(2) }

    context 'when model has precomputed version count' do
      before do
        allow(model3).to receive(:version_count).and_return(1)
      end

      it 'returns the value of model version count' do
        is_expected.to eq(1)
      end
    end
  end

  describe '#candidate_count' do
    let(:candidates) { build_stubbed_list(:ml_candidates, 2, experiment: model4.default_experiment) }

    before do
      allow(model4).to receive(:candidates).and_return(candidates)
    end

    subject { model4.present.candidate_count }

    it { is_expected.to eq(2) }
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

  describe '#latest_version_path' do
    subject { model.present.latest_version_path }

    context 'when model version does not have package' do
      let(:model) { model1 }

      it { is_expected.to be_nil }
    end

    context 'when latest model version has package' do
      let(:model) { model2 }

      it { is_expected.to eq("/#{project.full_path}/-/ml/models/#{model.id}/versions/#{model.latest_version.id}") }
    end
  end

  describe '#path' do
    subject { model1.present.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/models/#{model1.id}") }
  end

  describe '#author' do
    subject { model1.present.author }

    it { is_expected.to eq(model1.user) }
  end

  describe '#default_experiment_path' do
    subject { model1.present.default_experiment_path }

    it { is_expected.to eq("/#{model1.project.full_path}/-/ml/experiments/#{model1.default_experiment.iid}") }
  end
end

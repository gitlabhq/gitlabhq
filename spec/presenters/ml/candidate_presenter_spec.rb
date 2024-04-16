# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidatePresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:regular_candidate) { build_stubbed(:ml_candidates, :with_artifact, internal_id: 1, project: project) }
  let_it_be(:model_version) { build_stubbed(:ml_model_versions, :with_package, project: project) }
  let_it_be(:model_version_candidate) { model_version.candidate }

  let(:candidate) { regular_candidate }

  subject(:presenter) { candidate.present }

  describe '#path' do
    subject { presenter.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/candidates/#{candidate.iid}") }
  end

  describe '#artifact_show_path' do
    subject { presenter.artifact_show_path }

    context 'when candidate is not part of model a version' do
      it { is_expected.to eq("/#{project.full_path}/-/packages/#{candidate.package_id}") }
    end

    context 'when candidate is part of model version' do
      let(:candidate) { model_version_candidate }

      it { is_expected.to eq("/#{project.full_path}/-/packages/#{model_version.package_id}") }
    end
  end
end

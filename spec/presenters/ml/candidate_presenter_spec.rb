# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidatePresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:regular_candidate) { build_stubbed(:ml_candidates, :with_artifact, internal_id: 1, project: project) }
  let_it_be(:model_version) { build_stubbed(:ml_model_versions, :with_package, project: project) }
  let_it_be(:model_version_candidate) { model_version.candidate }
  let_it_be(:user) { project.owner }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project, user: user) }
  let_it_be(:build) { regular_candidate.ci_build = build_stubbed(:ci_build, pipeline: pipeline, user: user) }

  let(:candidate) { regular_candidate }

  subject(:presenter) { candidate.present(current_user: user) }

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

  describe '#ci_build' do
    subject { presenter.ci_build }

    context 'when candidate is associated to job' do
      it { is_expected.to eq(build) }

      context 'when ci job is not to be added' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
                              .with(user, :read_build, build)
                              .and_return(false)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#creator' do
    subject { presenter.creator }

    context 'when creator exists' do
      it { is_expected.to eq(user) }
    end

    context 'when creator not exist' do
      before do
        allow(candidate).to receive(:user).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end
end

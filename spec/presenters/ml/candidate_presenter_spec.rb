# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidatePresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:regular_candidate, freeze: false) do
    build_stubbed(:ml_candidates, :with_artifact, internal_id: 1, project: project)
  end

  let_it_be(:model_version) { build_stubbed(:ml_model_versions, :with_package, project: project) }
  let_it_be(:model_version_candidate) { model_version.candidate }
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:user, freeze: false) { project.owner }
  let_it_be(:pipeline, freeze: false) { build_stubbed(:ci_pipeline, project: project, user: user) }
  let_it_be(:build, freeze: false) do
    regular_candidate.ci_build = build_stubbed(:ci_build, pipeline: pipeline, user: user)
  end

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

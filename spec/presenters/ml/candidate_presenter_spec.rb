# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidatePresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:candidate) { build_stubbed(:ml_candidates, :with_artifact, internal_id: 1, project: project) }
  let_it_be(:presenter) { candidate.present }

  describe '#path' do
    subject { presenter.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/candidates/#{candidate.iid}") }
  end

  describe '#artifact_path' do
    subject { presenter.artifact_path }

    it { is_expected.to eq("/#{project.full_path}/-/packages/#{candidate.package_id}") }
  end
end

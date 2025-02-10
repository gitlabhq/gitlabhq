# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ExperimentPresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:experiment) { build_stubbed(:ml_experiments, user: user, project: project, iid: 100) }
  let_it_be(:user) { project.owner }

  subject(:presenter) { experiment.present(current_user: user) }

  describe '#path' do
    subject { presenter.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/experiments/#{experiment.iid}") }
  end

  describe '#candidate_count' do
    subject { presenter.candidate_count }

    it { is_expected.to eq(0) }
  end

  describe '#creator' do
    subject { presenter.creator }

    it { is_expected.to eq(experiment.user) }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::FindOrCreateExperimentService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:existing_experiment) { create(:ml_experiments, project: project, user: user) }

  let(:name) { 'new_experiment' }

  subject(:new_experiment) { described_class.new(project, name, user).execute }

  describe '#execute' do
    it 'creates an experiment using Ml::Experiment.find_or_create', :aggregate_failures do
      expect(Ml::Experiment).to receive(:find_or_create).and_call_original

      expect(new_experiment.name).to eq('new_experiment')
      expect(new_experiment.project).to eq(project)
      expect(new_experiment.user).to eq(user)
    end

    context 'when experiment already exists' do
      let(:name) { existing_experiment.name }

      it 'fetches existing experiment', :aggregate_failures do
        expect { new_experiment }.not_to change { Ml::Experiment.count }

        expect(new_experiment).to eq(existing_experiment)
      end
    end
  end
end

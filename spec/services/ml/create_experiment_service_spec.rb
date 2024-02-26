# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CreateExperimentService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:existing_experiment) { create(:ml_experiments, project: project, user: user) }

  let(:name) { 'new_experiment' }

  subject(:create_experiment) { described_class.new(project, name, user).execute }

  describe '#execute' do
    subject(:created_experiment) { create_experiment.payload }

    it 'creates an experiment', :aggregate_failures do
      expect(create_experiment).to be_success
      expect(created_experiment.name).to eq('new_experiment')
      expect(created_experiment.project).to eq(project)
      expect(created_experiment.user).to eq(user)
    end

    context 'when experiment already exists' do
      let(:name) { existing_experiment.name }

      it 'returns an error', :aggregate_failures do
        expect { create_experiment }.not_to change { Ml::Experiment.count }

        expect(create_experiment).to be_error
      end
    end
  end
end

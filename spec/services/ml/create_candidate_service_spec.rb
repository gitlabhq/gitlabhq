# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CreateCandidateService, feature_category: :mlops do
  describe '#execute' do
    let_it_be(:model_version) { create(:ml_model_versions, candidate: nil) }
    let_it_be(:experiment) { create(:ml_experiments, project: model_version.project) }

    let(:params) { {} }

    subject(:candidate) { described_class.new(experiment, params).execute }

    context 'with default parameters' do
      it 'creates a candidate' do
        expect { candidate }.to change { experiment.candidates.count }.by(1)
      end

      it 'gives a fake name' do
        expect(candidate.name).to match(/[a-z]+-[a-z]+-[a-z]+-\d+/)
      end

      it 'sets the correct values', :aggregate_failures do
        expect(candidate.start_time).to eq(0)
        expect(candidate.experiment).to be(experiment)
        expect(candidate.project).to be(experiment.project)
        expect(candidate.user).to be_nil
      end
    end

    context 'when parameters are passed' do
      let(:params) do
        {
          start_time: 1234,
          name: 'candidate_name',
          model_version: model_version,
          user: experiment.user
        }
      end

      context 'with default parameters' do
        it 'creates a candidate' do
          expect { candidate }.to change { experiment.candidates.count }.by(1)
        end

        it 'sets the correct values', :aggregate_failures do
          expect(candidate.start_time).to eq(1234)
          expect(candidate.experiment).to be(experiment)
          expect(candidate.project).to be(experiment.project)
          expect(candidate.user).to be(experiment.user)
          expect(candidate.name).to eq('candidate_name')
          expect(candidate.model_version_id).to eq(model_version.id)
        end
      end
    end
  end
end

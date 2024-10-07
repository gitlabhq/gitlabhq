# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::DestroyCandidateService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:model) { create(:ml_models, project: project) }

  let(:candidate) { create(:ml_candidates, :with_ml_model, :with_artifact, project: project) }
  let(:service) { described_class.new(candidate, user) }

  describe '#execute' do
    subject(:destroy_result) { service.execute }

    context 'when candidate is successfully destroyed' do
      it 'returns a success response' do
        expect(destroy_result).to be_success
      end

      it 'destroys the candidate' do
        expect(destroy_result).to be_success
        expect(destroy_result.payload[:candidate]).to eq(candidate)
        expect(Ml::Candidate.find_by(id: candidate.id)).to be_nil
      end
    end

    context 'when candidate fails to destroy' do
      before do
        allow(candidate).to receive(:destroy).and_return(false)
      end

      it 'returns an error response' do
        expect(destroy_result).to be_error
      end
    end
  end
end

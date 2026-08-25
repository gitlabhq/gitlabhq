# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RiskOutcome, feature_category: :duo_code_review do
  describe 'associations' do
    it { is_expected.to belong_to(:risk_assessment).class_name('MergeRequests::RiskAssessment').required }
  end

  describe 'sharding key' do
    let_it_be(:risk_assessment) { create(:merge_requests_risk_assessment) }

    subject { build(:merge_requests_risk_outcome, risk_assessment: risk_assessment, project_id: nil) }

    it { is_expected.to populate_sharding_key(:project_id).with(risk_assessment.project_id) }

    context 'when project_id cannot be derived' do
      let(:risk_outcome) { build(:merge_requests_risk_outcome, risk_assessment: nil, project_id: nil) }

      it 'is invalid' do
        expect(risk_outcome).to be_invalid
        expect(risk_outcome.errors[:project_id]).to include("can't be blank")
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:observed_at) }
    it { is_expected.to validate_presence_of(:signal_type) }
    it { is_expected.to validate_presence_of(:confidence) }

    it { is_expected.to allow_value(0, Gitlab::Database::MAX_SMALLINT_VALUE).for(:signal_type) }
    it { is_expected.not_to allow_value(-1, Gitlab::Database::MAX_SMALLINT_VALUE + 1).for(:signal_type) }
    it { is_expected.to allow_value(0, Gitlab::Database::MAX_SMALLINT_VALUE).for(:confidence) }
    it { is_expected.not_to allow_value(-1, Gitlab::Database::MAX_SMALLINT_VALUE + 1).for(:confidence) }

    describe 'signal_type uniqueness' do
      let_it_be(:existing) { create(:merge_requests_risk_outcome) }

      it 'rejects a second outcome with the same signal type for the assessment' do
        duplicate = build(:merge_requests_risk_outcome,
          risk_assessment: existing.risk_assessment, signal_type: existing.signal_type)

        expect(duplicate).to be_invalid
        expect(duplicate.errors[:signal_type]).to include('has already been taken')
      end

      it 'allows the same signal type under a different assessment' do
        other = build(:merge_requests_risk_outcome,
          risk_assessment: create(:merge_requests_risk_assessment), signal_type: existing.signal_type)

        expect(other).to be_valid
      end
    end

    describe 'evidence' do
      let(:risk_outcome) { build(:merge_requests_risk_outcome) }

      let(:evidence) do
        { commit_sha: 'abc123' }
      end

      before do
        risk_outcome.evidence = evidence
      end

      it 'matches the evidence json schema' do
        expect(risk_outcome.evidence.as_json).to match_schema(
          Rails.root.join('app/validators/json_schemas/merge_requests_risk_outcome_evidence.json')
        )
      end

      context 'when not an object' do
        let(:evidence) { 'not-an-object' }

        it 'is invalid' do
          expect(risk_outcome).not_to be_valid
          expect(risk_outcome.errors[:evidence]).to be_present
        end
      end

      context 'when it exceeds the size limit' do
        let(:evidence) { { commit_sha: 'a' * 64.kilobytes } }

        it 'is invalid' do
          expect(risk_outcome).not_to be_valid
          expect(risk_outcome.errors[:evidence]).to include(/is too large/)
        end
      end
    end
  end
end

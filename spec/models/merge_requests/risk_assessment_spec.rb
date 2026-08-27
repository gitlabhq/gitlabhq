# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RiskAssessment, feature_category: :duo_code_review do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).required }
    it { is_expected.to have_many(:risk_outcomes).class_name('MergeRequests::RiskOutcome') }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, completed: 1, failed: 2) }
  end

  describe 'sharding key' do
    let_it_be(:merge_request) { create(:merge_request) }

    subject { build(:merge_requests_risk_assessment, merge_request: merge_request, project_id: nil) }

    it { is_expected.to populate_sharding_key(:project_id).with(merge_request.project_id) }

    context 'when project_id cannot be derived' do
      let(:risk_assessment) { build(:merge_requests_risk_assessment, merge_request: nil, project_id: nil) }

      it 'is invalid' do
        expect(risk_assessment).to be_invalid
        expect(risk_assessment.errors[:project_id]).to include("can't be blank")
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:diff_sha) }
    it { is_expected.to validate_length_of(:diff_sha).is_at_most(64) }
    it { is_expected.to validate_length_of(:scoring_function_version).is_at_most(20) }
    it { is_expected.to validate_length_of(:rationale).is_at_most(2048) }

    it { is_expected.to allow_value(nil, 0, 50, 100).for(:score) }
    it { is_expected.not_to allow_value(-1, 101).for(:score) }
    it { is_expected.to allow_value(nil, 0, 50, 100).for(:confidence) }
    it { is_expected.not_to allow_value(-1, 101).for(:confidence) }

    describe 'merge_request_id uniqueness' do
      let_it_be(:existing) { create(:merge_requests_risk_assessment) }

      it 'rejects a second assessment for the same merge request' do
        duplicate = build(:merge_requests_risk_assessment, merge_request: existing.merge_request)

        expect(duplicate).to be_invalid
        expect(duplicate.errors[:merge_request_id]).to include('has already been taken')
      end
    end

    describe 'classification' do
      let(:risk_assessment) { build(:merge_requests_risk_assessment) }

      let(:classification) do
        { verdict: 'low_risk' }
      end

      before do
        risk_assessment.classification = classification
      end

      it 'matches the classification json schema' do
        expect(risk_assessment.classification.as_json).to match_schema(
          Rails.root.join('app/validators/json_schemas/merge_requests_risk_assessment_classification.json')
        )
      end

      context 'when not an object' do
        let(:classification) { 'not-an-object' }

        it 'is invalid' do
          expect(risk_assessment).not_to be_valid
          expect(risk_assessment.errors[:classification]).to be_present
        end
      end

      context 'when it exceeds the size limit' do
        let(:classification) { { verdict: 'a' * 64.kilobytes } }

        it 'is invalid' do
          expect(risk_assessment).not_to be_valid
          expect(risk_assessment.errors[:classification]).to include(/is too large/)
        end
      end
    end

    describe 'signal_breakdown' do
      let(:risk_assessment) { build(:merge_requests_risk_assessment) }

      let(:signal_breakdown) do
        [{ signal: 'large_diff' }]
      end

      before do
        risk_assessment.signal_breakdown = signal_breakdown
      end

      it 'matches the signal_breakdown json schema' do
        expect(risk_assessment.signal_breakdown.as_json).to match_schema(
          Rails.root.join('app/validators/json_schemas/merge_requests_risk_assessment_signal_breakdown.json')
        )
      end

      context 'when not an array' do
        let(:signal_breakdown) { { signal: 'large_diff' } }

        it 'is invalid' do
          expect(risk_assessment).not_to be_valid
          expect(risk_assessment.errors[:signal_breakdown]).to be_present
        end
      end

      context 'when it exceeds the size limit' do
        let(:signal_breakdown) { [{ signal: 'a' * 64.kilobytes }] }

        it 'is invalid' do
          expect(risk_assessment).not_to be_valid
          expect(risk_assessment.errors[:signal_breakdown]).to include(/is too large/)
        end
      end
    end
  end

  describe '#tier' do
    it 'is always nil until the scoring function and tier thresholds exist' do
      risk_assessment = build(:merge_requests_risk_assessment, score: 90)

      expect(risk_assessment.tier).to be_nil
    end
  end

  describe '#stale?' do
    let(:merge_request) { build(:merge_request) }
    let(:risk_assessment) { build(:merge_requests_risk_assessment, merge_request: merge_request) }

    context 'when diff_sha matches the merge request head' do
      it 'returns false' do
        risk_assessment.diff_sha = merge_request.diff_head_sha

        expect(risk_assessment).not_to be_stale
      end
    end

    context 'when diff_sha does not match the merge request head' do
      it 'returns true' do
        risk_assessment.diff_sha = Digest::SHA1.hexdigest(SecureRandom.hex) # rubocop:disable Fips/SHA1 -- test data

        expect(risk_assessment).to be_stale
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::TrustScore, feature_category: :instance_resiliency do
  let_it_be(:user) { create(:user) }

  let(:correlation_id) { nil }

  let(:abuse_trust_score) do
    create(:abuse_trust_score, user: user, correlation_id_value: correlation_id)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:score) }
    it { is_expected.to validate_presence_of(:source) }
  end

  describe 'create' do
    subject { abuse_trust_score }

    before do
      allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('123abc')
    end

    context 'if correlation ID is nil' do
      it 'adds the correlation id' do
        expect(abuse_trust_score.correlation_id_value).to eq('123abc')
      end
    end

    context 'if correlation ID is set' do
      let(:correlation_id) { 'already-set' }

      it 'does not change the correlation id' do
        expect(abuse_trust_score.correlation_id_value).to eq('already-set')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::UserTrustScore, feature_category: :instance_resiliency do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let(:user_1_scores) { described_class.new(user1) }
  let(:user_2_scores) { described_class.new(user2) }

  describe '#spammer?' do
    context 'when the user is a spammer' do
      before do
        allow(user_1_scores).to receive(:spam_score).and_return(0.9)
      end

      it 'classifies the user as a spammer' do
        expect(user_1_scores).to be_spammer
      end
    end

    context 'when the user is not a spammer' do
      before do
        allow(user_1_scores).to receive(:spam_score).and_return(0.1)
      end

      it 'does not classify the user as a spammer' do
        expect(user_1_scores).not_to be_spammer
      end
    end
  end

  describe '#spam_score' do
    context 'when the user is a spammer' do
      before do
        create(:abuse_trust_score, user: user1, score: 0.8)
        create(:abuse_trust_score, user: user1, score: 0.9)
      end

      it 'returns the expected score' do
        expect(user_1_scores.spam_score).to be_within(0.01).of(0.85)
      end
    end

    context 'when the user is not a spammer' do
      before do
        create(:abuse_trust_score, user: user1, score: 0.1)
        create(:abuse_trust_score, user: user1, score: 0.0)
      end

      it 'returns the expected score' do
        expect(user_1_scores.spam_score).to be_within(0.01).of(0.05)
      end
    end
  end

  describe '#telesign_score' do
    context 'when the user has a telesign risk score' do
      before do
        create(:abuse_trust_score, user: user1, score: 12.0, source: :telesign)
        create(:abuse_trust_score, user: user1, score: 24.0, source: :telesign)
      end

      it 'returns the latest score' do
        expect(user_1_scores.telesign_score).to be(24.0)
      end
    end

    context 'when the user does not have a telesign risk score' do
      it 'defaults to zero' do
        expect(user_2_scores.telesign_score).to be(0.0)
      end
    end
  end

  describe '#arkose_global_score' do
    context 'when the user has an arkose global risk score' do
      before do
        create(:abuse_trust_score, user: user1, score: 12.0, source: :arkose_global_score)
        create(:abuse_trust_score, user: user1, score: 24.0, source: :arkose_global_score)
      end

      it 'returns the latest score' do
        expect(user_1_scores.arkose_global_score).to be(24.0)
      end
    end

    context 'when the user does not have an arkose global risk score' do
      it 'defaults to zero' do
        expect(user_2_scores.arkose_global_score).to be(0.0)
      end
    end
  end

  describe '#arkose_custom_score' do
    context 'when the user has an arkose custom risk score' do
      before do
        create(:abuse_trust_score, user: user1, score: 12.0, source: :arkose_custom_score)
        create(:abuse_trust_score, user: user1, score: 24.0, source: :arkose_custom_score)
      end

      it 'returns the latest score' do
        expect(user_1_scores.arkose_custom_score).to be(24.0)
      end
    end

    context 'when the user does not have an arkose custom risk score' do
      it 'defaults to zero' do
        expect(user_2_scores.arkose_custom_score).to be(0.0)
      end
    end
  end

  describe '#remove_old_scores' do
    let(:source) { :spamcheck }

    subject(:remove_old_scores) { described_class.new(user1).remove_old_scores(source) }

    context 'if max events is exceeded' do
      before do
        stub_const('AntiAbuse::UserTrustScore::MAX_EVENTS', 2)
      end

      it 'removes the oldest events' do
        first = create(:abuse_trust_score, source: source, user: user1)
        create(:abuse_trust_score, source: source, user: user1)
        create(:abuse_trust_score, source: source, user: user1)

        expect { remove_old_scores }.to change { user1.abuse_trust_scores.count }.from(3).to(2)
        expect(AntiAbuse::TrustScore.find_by_id(first.id)).to eq(nil)
      end
    end
  end
end

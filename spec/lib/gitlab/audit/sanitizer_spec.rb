# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Audit::Sanitizer, feature_category: :audit_events do
  describe '.sanitize_user_agent' do
    subject(:sanitized_user_agent) { described_class.sanitize_user_agent(user_agent) }

    context 'when user_agent is nil' do
      let(:user_agent) { nil }

      it { is_expected.to be_nil }
    end

    context 'when user_agent is blank' do
      let(:user_agent) { '' }

      it { is_expected.to be_nil }
    end

    context 'when user_agent is a normal string' do
      let(:user_agent) { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }

      it { is_expected.to eq(user_agent) }
    end

    context 'when user_agent exceeds max length' do
      let(:user_agent) { 'A' * 300 }

      it 'truncates to USER_AGENT_MAX_LENGTH' do
        expect(sanitized_user_agent).to eq('A' * 250)
        expect(sanitized_user_agent.length).to eq(250)
      end
    end

    context 'when user_agent is exactly at max length' do
      let(:user_agent) { 'B' * 250 }

      it 'does not truncate' do
        expect(sanitized_user_agent).to eq(user_agent)
        expect(sanitized_user_agent.length).to eq(250)
      end
    end

    context 'when user_agent contains non-printable/control characters' do
      let(:user_agent) { "Mozilla/5.0\x00\x01\x02 (evil\x7Fbot)" }

      it 'strips non-printable and control characters' do
        expect(sanitized_user_agent).to eq('Mozilla/5.0 (evilbot)')
      end
    end

    context 'when user_agent contains special characters' do
      let(:user_agent) { 'curl/8.7.1 (special-chars: <>&")' }

      it 'preserves special characters' do
        expect(sanitized_user_agent).to eq(user_agent)
      end
    end

    context 'when user_agent is a symbol' do
      let(:user_agent) { :symbol }

      it 'converts to string' do
        expect(sanitized_user_agent).to eq('symbol')
      end
    end
  end
end

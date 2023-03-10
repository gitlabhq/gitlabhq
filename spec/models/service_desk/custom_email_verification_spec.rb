# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomEmailVerification, feature_category: :service_desk do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:verification) { build_stubbed(:service_desk_custom_email_verification, project: project) }
  let(:token) { 'XXXXXXXXXXXX' }

  describe '.generate_token' do
    it 'matches expected output' do
      expect(described_class.generate_token).to match(/\A\p{Alnum}{12}\z/)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:state) }
  end

  describe '#accepted_until' do
    context 'when no custom email is set up' do
      it 'returns nil' do
        expect(subject.accepted_until).to be_nil
      end
    end

    context 'when custom email is set up' do
      subject { verification.accepted_until }

      it { is_expected.to be_nil }

      context 'when verification process started' do
        let(:triggered_at) { 2.minutes.ago }

        before do
          verification.assign_attributes(
            state: "running",
            triggered_at: triggered_at,
            triggerer: user,
            token: token
          )
        end

        it { is_expected.to eq(described_class::TIMEFRAME.since(triggered_at)) }
      end
    end
  end

  describe '#in_timeframe?' do
    context 'when no custom email is set up' do
      it 'returns false' do
        expect(subject).not_to be_in_timeframe
      end
    end

    context 'when custom email is set up' do
      it { is_expected.not_to be_in_timeframe }

      context 'when verification process started' do
        let(:triggered_at) { 1.second.ago }

        before do
          subject.assign_attributes(
            state: "running",
            triggered_at: triggered_at,
            triggerer: user,
            token: token
          )
        end

        it { is_expected.to be_in_timeframe }

        context 'and timeframe was missed' do
          let(:triggered_at) { (described_class::TIMEFRAME + 1).ago }

          before do
            subject.triggered_at = triggered_at
          end

          it { is_expected.not_to be_in_timeframe }
        end
      end
    end
  end

  describe 'encrypted #token' do
    subject { build_stubbed(:service_desk_custom_email_verification, token: token) }

    it 'saves and retrieves the encrypted token and iv correctly' do
      expect(subject.encrypted_token).not_to be_nil
      expect(subject.encrypted_token_iv).not_to be_nil

      expect(subject.token).to eq(token)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:triggerer) }

    it 'can access service desk setting from project' do
      setting = build_stubbed(:service_desk_setting, project: project)

      expect(verification.service_desk_setting).to eq(setting)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::TwoFactorAuthVerifier do
  let(:user) { create(:user) }

  subject { described_class.new(user) }

  describe '#two_factor_authentication_required?' do
    describe 'when it is required on application level' do
      it 'returns true' do
        stub_application_setting require_two_factor_authentication: true

        expect(subject.two_factor_authentication_required?).to be_truthy
      end
    end

    describe 'when it is required on group level' do
      it 'returns true' do
        allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)

        expect(subject.two_factor_authentication_required?).to be_truthy
      end
    end

    describe 'when it is not required' do
      it 'returns false when not required on group level' do
        allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(false)

        expect(subject.two_factor_authentication_required?).to be_falsey
      end
    end
  end

  describe '#current_user_needs_to_setup_two_factor?' do
    it 'returns false when current_user is nil' do
      expect(described_class.new(nil).current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns false when current_user does not have temp email' do
      allow(user).to receive(:two_factor_enabled?).and_return(false)
      allow(user).to receive(:temp_oauth_email?).and_return(true)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns false when current_user has 2fa disabled' do
      allow(user).to receive(:temp_oauth_email?).and_return(false)
      allow(user).to receive(:two_factor_enabled?).and_return(true)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns true when user requires 2fa authentication' do
      allow(user).to receive(:two_factor_enabled?).and_return(false)
      allow(user).to receive(:temp_oauth_email?).and_return(false)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_truthy
    end
  end

  describe '#two_factor_grace_period' do
    it 'returns grace period from settings if there is no period from groups' do
      stub_application_setting two_factor_grace_period: 2
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(false)

      expect(subject.two_factor_grace_period).to eq(2)
    end

    it 'returns grace period from groups if there is no period from settings' do
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)
      allow(user).to receive(:two_factor_grace_period).and_return(3)

      expect(subject.two_factor_grace_period).to eq(3)
    end

    it 'returns minimal grace period if there is grace period from settings and from group' do
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)
      allow(user).to receive(:two_factor_grace_period).and_return(3)
      stub_application_setting two_factor_grace_period: 2

      expect(subject.two_factor_grace_period).to eq(2)
    end
  end

  describe '#two_factor_grace_period_expired?' do
    before do
      allow(user).to receive(:otp_grace_period_started_at).and_return(4.hours.ago)
    end

    it 'returns true if the grace period has expired' do
      allow(subject).to receive(:two_factor_grace_period).and_return(2)

      expect(subject.two_factor_grace_period_expired?).to be_truthy
    end

    it 'returns false if the grace period has not expired' do
      allow(subject).to receive(:two_factor_grace_period).and_return(6)

      expect(subject.two_factor_grace_period_expired?).to be_falsey
    end

    context 'when otp_grace_period_started_at is nil' do
      it 'returns false' do
        allow(user).to receive(:otp_grace_period_started_at).and_return(nil)

        expect(subject.two_factor_grace_period_expired?).to be_falsey
      end
    end
  end
end

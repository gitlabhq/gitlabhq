# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomEmailVerification, feature_category: :service_desk do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:generate_token_pattern) { /\A\p{Alnum}{12}\z/ }

  describe '.generate_token' do
    it 'matches expected output' do
      expect(described_class.generate_token).to match(generate_token_pattern)
    end
  end

  describe 'validations' do
    subject { build(:service_desk_custom_email_verification, project: project) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:state) }

    context 'when status is :started' do
      before do
        subject.mark_as_started!(user)
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_length_of(:token).is_equal_to(12) }

      it 'matches .generate_token pattern' do
        expect(subject.token).to match(generate_token_pattern)
      end

      it { is_expected.to validate_presence_of(:triggerer) }
      it { is_expected.to validate_presence_of(:triggered_at) }
      it { is_expected.to validate_absence_of(:error) }
    end

    context 'when status is :finished' do
      before do
        subject.mark_as_started!(user)
        subject.mark_as_finished!
      end

      it { is_expected.to validate_absence_of(:token) }
      it { is_expected.to validate_absence_of(:error) }
    end

    context 'when status is :failed' do
      before do
        subject.mark_as_started!(user)
        subject.mark_as_failed!(:smtp_host_issue)
      end

      it { is_expected.to validate_presence_of(:error) }
      it { is_expected.to validate_absence_of(:token) }
    end
  end

  describe 'status state machine' do
    subject { build(:service_desk_custom_email_verification, project: project) }

    describe 'transitioning to started' do
      it 'records the started at time and generates token' do
        subject.mark_as_started!(user)

        is_expected.to be_started
        expect(subject.token).to be_present
        expect(subject.triggered_at).to be_present
        expect(subject.triggerer).to eq(user)
      end
    end

    describe 'transitioning to finished' do
      it 'removes the generated token' do
        subject.mark_as_started!(user)
        subject.mark_as_finished!

        is_expected.to be_finished
        expect(subject.token).not_to be_present
      end
    end

    describe 'transitioning to failed' do
      let(:error) { :smtp_host_issue }

      it 'removes the generated token' do
        subject.mark_as_started!(user)
        subject.mark_as_failed!(error)

        is_expected.to be_failed
        expect(subject.token).not_to be_present
        expect(subject.error).to eq(error.to_s)
      end
    end
  end

  describe 'scopes' do
    let_it_be(:verification) { create(:service_desk_custom_email_verification, project: project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:overdue_verification) do
      create(:service_desk_custom_email_verification, :overdue, project: other_project)
    end

    describe '.overdue' do
      it 'returns verifications that are overdue' do
        expect(described_class.overdue).to eq([overdue_verification])
      end
    end
  end

  describe '#accepted_until' do
    it 'returns nil' do
      expect(subject.accepted_until).to be_nil
    end

    context 'when state is :started and successfully transitioned' do
      let(:triggered_at) { 2.minutes.ago }

      before do
        subject.project = project
        subject.mark_as_started!(user)
      end

      it 'returns correct timeframe end time' do
        expect(subject.accepted_until).to eq(described_class::TIMEFRAME.since(subject.triggered_at))
      end

      context 'when triggered_at is not set' do
        it 'returns nil' do
          subject.triggered_at = nil
          expect(subject.accepted_until).to be nil
        end
      end
    end
  end

  describe '#in_timeframe?' do
    it { is_expected.not_to be_in_timeframe }

    context 'when state is :started and successfully transitioned' do
      before do
        subject.project = project
        subject.mark_as_started!(user)
      end

      it { is_expected.to be_in_timeframe }

      context 'and timeframe was missed' do
        before do
          subject.triggered_at = (described_class::TIMEFRAME + 1).ago
        end

        it { is_expected.not_to be_in_timeframe }
      end
    end
  end

  describe 'encrypted #token' do
    let(:token) { 'XXXXXXXXXXXX' }

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
      subject.project = project
      setting = build_stubbed(:service_desk_setting, project: subject.project)

      expect(subject.service_desk_setting).to eq(setting)
    end
  end
end

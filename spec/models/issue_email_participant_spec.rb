# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipant, feature_category: :service_desk do
  describe "Associations" do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Modules' do
    subject { described_class }

    it { is_expected.to include_module(Presentable) }
  end

  describe 'Validations' do
    subject { build(:issue_email_participant) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to([:issue_id]).ignoring_case_sensitivity }

    it_behaves_like 'an object with RFC3696 compliant email-formatted attributes', :email

    it 'is invalid if the email is nil' do
      subject.email = nil

      expect(subject).to be_invalid
    end
  end

  describe 'Scopes' do
    describe '.with_emails' do
      let!(:participant) { create(:issue_email_participant, email: 'user@example.com') }
      let!(:participant1) { create(:issue_email_participant, email: 'user1@example.com') }
      let!(:participant2) { create(:issue_email_participant, email: 'user2@example.com') }

      it 'returns only participant with matching emails' do
        expect(described_class.with_emails([participant.email, participant1.email])).to match_array(
          [participant, participant1]
        )
      end
    end
  end
end

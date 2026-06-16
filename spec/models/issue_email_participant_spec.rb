# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipant, feature_category: :service_desk do
  describe "Associations" do
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:namespace) }
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

    describe '.with_issue_and_project_ordered' do
      let_it_be(:participant1) { create(:issue_email_participant) }
      let_it_be(:participant2) { create(:issue_email_participant) }
      let_it_be(:participant3) { create(:issue_email_participant) }

      it 'returns participants ordered by id ascending' do
        expect(described_class.with_issue_and_project_ordered).to eq([participant1, participant2, participant3])
      end

      it 'preloads issue and project associations' do
        baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          described_class.with_issue_and_project_ordered
        end

        create(:issue_email_participant)

        expect { described_class.with_issue_and_project_ordered }.to issue_same_number_of_queries_as(baseline)
      end
    end
  end
end

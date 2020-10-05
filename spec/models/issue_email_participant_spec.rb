# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipant do
  describe "Associations" do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    subject { build(:issue_email_participant) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to([:issue_id]) }

    it_behaves_like 'an object with RFC3696 compliant email-formated attributes', :email
  end
end

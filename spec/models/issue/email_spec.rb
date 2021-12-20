# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue::Email do
  describe 'Associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    subject { build(:issue_email) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:email_message_id) }
    it { is_expected.to validate_length_of(:email_message_id).is_at_most(1000) }
    it { is_expected.to validate_presence_of(:email_message_id) }
  end
end

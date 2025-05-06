# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::IssueAssignmentEvent, feature_category: :value_stream_management, type: :model do
  subject(:event) { build(:issue_assignment_event) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:issue) }
  end
end

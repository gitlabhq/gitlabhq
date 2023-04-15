# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::MergeRequestAssignmentEvent, feature_category: :value_stream_management, type: :model do
  subject(:event) { build(:merge_request_assignment_event) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:merge_request) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:merge_request) }
  end
end

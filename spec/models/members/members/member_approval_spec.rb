# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MemberApproval, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:member_namespace) }
    it { is_expected.to belong_to(:reviewed_by) }
    it { is_expected.to belong_to(:requested_by) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:new_access_level) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:member_namespace) }
  end
end

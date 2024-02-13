# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::MemberApproval, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:member_namespace) }
    it { is_expected.to belong_to(:reviewed_by) }
    it { is_expected.to belong_to(:requested_by) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:new_access_level) }
    it { is_expected.to validate_presence_of(:old_access_level) }
  end
end

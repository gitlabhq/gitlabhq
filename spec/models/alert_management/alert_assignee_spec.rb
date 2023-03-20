# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertAssignee do
  describe 'associations' do
    it { is_expected.to belong_to(:alert) }

    it do
      is_expected.to belong_to(:assignee).class_name('User')
        .with_foreign_key(:user_id).inverse_of(:alert_assignees)
    end
  end

  describe 'validations' do
    let(:alert) { create(:alert_management_alert) }
    let(:user) { create(:user) }

    subject { alert.alert_assignees.build(assignee: user) }

    it { is_expected.to validate_presence_of(:alert) }
    it { is_expected.to validate_presence_of(:assignee) }
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:alert_id) }
  end
end

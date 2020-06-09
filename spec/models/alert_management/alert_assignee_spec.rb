# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertAssignee do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:alert1) { create(:alert_management_alert, assignees: [user1, user2]) }
  let_it_be(:alert2) { create(:alert_management_alert, assignees: [user2]) }

  describe 'associations' do
    it { is_expected.to belong_to(:alert) }
    it { is_expected.to belong_to(:assignee) }
  end

  describe 'validations' do
    subject { alert1.alert_assignees.build(assignee: user1) }

    it { is_expected.to validate_presence_of(:alert) }
    it { is_expected.to validate_presence_of(:assignee) }
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:alert_id) }
  end

  describe 'scopes' do
    describe '.for_alert_ids' do
      let(:alert_ids) { alert1.id }

      subject { described_class.for_alert_ids(alert_ids) }

      it { is_expected.to contain_exactly(*alert1.reload.alert_assignees) }

      context 'with multiple ids' do
        let(:alert_ids) { [alert1.id, alert2.id] }

        it { is_expected.to contain_exactly(*alert1.reload.alert_assignees, *alert2.reload.alert_assignees) }
      end
    end
  end
end

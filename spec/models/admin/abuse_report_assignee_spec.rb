# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportAssignee, feature_category: :insider_threat do
  let_it_be(:report) { create(:abuse_report) }
  let_it_be(:user) { create(:admin) }

  subject(:abuse_report_assignee) { report.admin_abuse_report_assignees.build(assignee: user) }

  it { expect(abuse_report_assignee).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:abuse_report) }
    it { is_expected.to belong_to(:assignee).class_name('User').with_foreign_key(:user_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:assignee).scoped_to(:abuse_report_id) }
  end

  context 'with loose foreign key on abuse_report_assignees.user_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { user }
      let_it_be(:report) { create(:abuse_report).tap { |r| r.update!(assignees: [parent]) } }
      let_it_be(:model) { report.admin_abuse_report_assignees.first }
    end
  end
end

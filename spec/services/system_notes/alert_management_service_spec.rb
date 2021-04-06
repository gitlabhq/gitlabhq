# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::AlertManagementService do
  let_it_be(:author)   { create(:user) }
  let_it_be(:project)  { create(:project, :repository) }
  let_it_be(:noteable) { create(:alert_management_alert, :with_issue, :acknowledged, project: project) }

  describe '#create_new_alert' do
    subject { described_class.new(noteable: noteable, project: project).create_new_alert('Some Service') }

    it_behaves_like 'a system note' do
      let(:author) { User.alert_bot }
      let(:action) { 'new_alert_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq('logged an alert from **Some Service**')
    end
  end

  describe '#change_alert_status' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_alert_status(noteable) }

    it_behaves_like 'a system note' do
      let(:action) { 'status' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq("changed the status to **Acknowledged**")
    end
  end

  describe '#new_alert_issue' do
    let_it_be(:issue) { noteable.issue }

    subject { described_class.new(noteable: noteable, project: project, author: author).new_alert_issue(issue) }

    it_behaves_like 'a system note' do
      let(:action) { 'alert_issue_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq("created issue #{issue.to_reference(project)} for this alert")
    end
  end

  describe '#closed_alert_issue' do
    let_it_be(:issue) { noteable.issue }

    subject { described_class.new(noteable: noteable, project: project, author: author).closed_alert_issue(issue) }

    it_behaves_like 'a system note' do
      let(:action) { 'status' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq("changed the status to **Resolved** by closing issue #{issue.to_reference(project)}")
    end
  end

  describe '#log_resolving_alert' do
    subject { described_class.new(noteable: noteable, project: project).log_resolving_alert('Some Service') }

    it_behaves_like 'a system note' do
      let(:author) { User.alert_bot }
      let(:action) { 'new_alert_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq('logged a recovery alert from **Some Service**')
    end
  end
end

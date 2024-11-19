# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::AlertManagementService, feature_category: :groups_and_projects do
  let_it_be(:author)   { create(:user) }
  let_it_be(:project)  { create(:project, :repository) }
  let_it_be(:noteable) { create(:alert_management_alert, :with_incident, :acknowledged, project: project) }

  describe '#create_new_alert' do
    subject { described_class.new(noteable: noteable, container: project).create_new_alert('Some Service') }

    it_behaves_like 'a system note' do
      let(:author) { Users::Internal.alert_bot }
      let(:action) { 'new_alert_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq('logged an alert from **Some Service**')
    end
  end

  describe '#change_alert_status' do
    subject { described_class.new(noteable: noteable, container: project, author: author).change_alert_status(reason) }

    context 'with no specified reason' do
      let(:reason) { nil }

      it_behaves_like 'a system note' do
        let(:action) { 'status' }
      end

      it 'has the appropriate message' do
        expect(subject.note).to eq("changed the status to **Acknowledged**")
      end
    end

    context 'with reason provided' do
      let(:reason) { ' by changing incident status' }

      it 'has the appropriate message' do
        expect(subject.note).to eq("changed the status to **Acknowledged** by changing incident status")
      end
    end
  end

  describe '#new_alert_issue' do
    let_it_be(:issue) { noteable.issue }

    subject { described_class.new(noteable: noteable, container: project, author: author).new_alert_issue(issue) }

    it_behaves_like 'a system note' do
      let(:action) { 'alert_issue_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq("created incident #{issue.to_reference(project)} for this alert")
    end
  end

  describe '#log_resolving_alert' do
    subject { described_class.new(noteable: noteable, container: project).log_resolving_alert('Some Service') }

    it_behaves_like 'a system note' do
      let(:author) { Users::Internal.alert_bot }
      let(:action) { 'new_alert_added' }
    end

    it 'has the appropriate message' do
      expect(subject.note).to eq('logged a recovery alert from **Some Service**')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::ProcessAlertWorker do
  let_it_be(:project) { create(:project) }

  describe '#perform' do
    let(:alert) { :alert }
    let(:create_issue_service) { spy(:create_issue_service) }

    subject { described_class.new.perform(project.id, alert) }

    it 'calls create issue service' do
      expect(Project).to receive(:find_by_id).and_call_original

      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, :alert)
        .and_return(create_issue_service)

      expect(create_issue_service).to receive(:execute)

      subject
    end

    context 'with invalid project' do
      let(:invalid_project_id) { 0 }

      subject { described_class.new.perform(invalid_project_id, alert) }

      it 'does not create issues' do
        expect(Project).to receive(:find_by_id).and_call_original
        expect(IncidentManagement::CreateIssueService).not_to receive(:new)

        subject
      end
    end
  end
end

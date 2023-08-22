# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::CloseIncidentWorker, feature_category: :incident_management do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:user) { Users::Internal.alert_bot }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue, reload: true) { create(:incident, project: project) }

    let(:issue_id) { issue.id }

    it 'calls the close issue service' do
      expect_next_instance_of(Issues::CloseService, container: project, current_user: user) do |service|
        expect(service).to receive(:execute).with(issue, system_note: false).and_call_original
      end

      expect { worker.perform(issue_id) }.to change { ResourceStateEvent.count }.by(1)
    end

    shared_examples 'does not call the close issue service' do
      specify do
        expect(Issues::CloseService).not_to receive(:new)

        expect { worker.perform(issue_id) }.not_to change { ResourceStateEvent.count }
      end
    end

    context 'when the incident does not exist' do
      let(:issue_id) { non_existing_record_id }

      it_behaves_like 'does not call the close issue service'
    end

    context 'when issue type is not incident' do
      before do
        issue.update!(work_item_type: WorkItems::Type.default_by_type(:issue))
      end

      it_behaves_like 'does not call the close issue service'
    end

    context 'when incident is not open' do
      before do
        issue.close
      end

      it_behaves_like 'does not call the close issue service'
    end

    context 'when incident fails to close' do
      before do
        allow_next_instance_of(Issues::CloseService) do |service|
          expect(service).to receive(:close_issue).and_return(issue)
        end
      end

      specify do
        expect { worker.perform(issue_id) }.not_to change { ResourceStateEvent.count }
      end
    end
  end
end

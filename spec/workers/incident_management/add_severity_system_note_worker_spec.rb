# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::AddSeveritySystemNoteWorker, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:issuable_severity) { create(:issuable_severity, issue: incident, severity: :medium) }

  describe '#perform' do
    let(:incident_id) { incident.id }
    let(:user_id) { user.id }

    subject(:perform) { described_class.new.perform(incident_id, user_id) }

    shared_examples 'does not add anything' do
      it 'does not change incident notes count' do
        expect { perform }.not_to change { incident.notes.count }
      end

      it 'does not create a timeline event' do
        expect(IncidentManagement::TimelineEvents::CreateService).not_to receive(:change_severity)
        perform
      end
    end

    context 'when incident and user exist' do
      it 'creates a system note' do
        expect { perform }.to change { incident.notes.where(author: user).count }.by(1)
      end

      it 'creates a timeline event' do
        expect(IncidentManagement::TimelineEvents::CreateService)
          .to receive(:change_severity)
          .with(incident, user)
          .and_call_original
        perform
      end
    end

    context 'when incident does not exist' do
      let(:incident_id) { -1 }

      it_behaves_like 'does not add anything'
    end

    context 'when incident_id is nil' do
      let(:incident_id) { nil }

      it_behaves_like 'does not add anything'
    end

    context 'when issue is not an incident' do
      let_it_be(:issue) { create(:issue, project: project) }

      let(:incident_id) { issue.id }

      it_behaves_like 'does not add anything'
    end

    context 'when user does not exist' do
      let(:user_id) { -1 }

      it_behaves_like 'does not add anything'
    end

    context 'when user_id is nil' do
      let(:user_id) { nil }

      it_behaves_like 'does not add anything'
    end
  end
end

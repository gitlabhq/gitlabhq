# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventPolicy, :models do
  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:user) { developer }
  let_it_be(:incident) { create(:incident, project: project, author: user) }

  let_it_be(:editable_timeline_event) do
    create(:incident_management_timeline_event, :editable, project: project, author: user, incident: incident)
  end

  let_it_be(:non_editable_timeline_event) do
    create(:incident_management_timeline_event, :non_editable, project: project, author: user, incident: incident)
  end

  describe '#rules' do
    subject(:policies) { described_class.new(user, timeline_event) }

    context 'when a user is not able to manage timeline events' do
      let_it_be(:user) { reporter }

      context 'when timeline event is editable' do
        let(:timeline_event) { editable_timeline_event }

        it 'does not allow to edit the timeline event' do
          is_expected.not_to be_allowed(:edit_incident_management_timeline_event)
        end
      end
    end

    context 'when a user is able to manage timeline events' do
      let_it_be(:user) { developer }

      context 'when timeline event is editable' do
        let(:timeline_event) { editable_timeline_event }

        it 'allows to edit the timeline event' do
          is_expected.to be_allowed(:edit_incident_management_timeline_event)
        end
      end

      context 'when timeline event is not editable' do
        let(:timeline_event) { non_editable_timeline_event }

        it 'does not allow to edit the timeline event' do
          is_expected.not_to be_allowed(:edit_incident_management_timeline_event)
        end
      end
    end
  end
end

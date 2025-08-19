# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PostCreationWorker, feature_category: :source_code_management do
  let_it_be(:user) { create :user }

  let(:worker) { described_class.new }
  let(:project) { create(:project) }

  subject { described_class.new.perform(project.id) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [project.id] }

    describe 'Incident timeline event tags' do
      context 'when project is nil' do
        let(:job_args) { [nil] }

        it 'does not create event tags' do
          expect { subject }.not_to change { IncidentManagement::TimelineEventTag.count }
        end
      end

      context 'when project is created', :aggregate_failures do
        it 'creates tags for the project' do
          expect { subject }.to change { IncidentManagement::TimelineEventTag.count }.by(6)

          expect(project.incident_management_timeline_event_tags.pluck_names).to match_array(
            ::IncidentManagement::TimelineEventTag::PREDEFINED_TAGS
          )
        end

        it 'raises error if record creation fails' do
          allow_next_instance_of(IncidentManagement::TimelineEventTag) do |tag|
            allow(tag).to receive(:valid?).and_return(false)
          end

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(an_instance_of(ActiveRecord::RecordInvalid), include(extra: { project_id: a_kind_of(Integer) })).twice
          subject

          expect(project.incident_management_timeline_event_tags).to be_empty
        end
      end
    end
  end
end

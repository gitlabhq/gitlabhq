# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::IncidentsService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project, author: user) }
  let_it_be(:timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident, author: author)
  end

  describe '#add_timeline_event' do
    subject { described_class.new(noteable: incident).add_timeline_event(timeline_event) }

    it_behaves_like 'a system note' do
      let(:noteable) { incident }
      let(:action) { 'timeline_event' }
    end

    it 'posts the correct text to the system note' do
      expect(subject.note).to match("added an incident timeline event")
    end
  end

  describe '#edit_timeline_event' do
    let(:was_changed) { :unknown }

    subject do
      described_class.new(noteable: incident).edit_timeline_event(timeline_event, author, was_changed: was_changed)
    end

    it_behaves_like 'a system note' do
      let(:noteable) { incident }
      let(:action) { 'timeline_event' }
    end

    context "when only timeline event's occurred_at was changed" do
      let(:was_changed) { :occurred_at }

      it 'posts the correct text to the system note' do
        expect(subject.note).to match("edited the event time/date on incident timeline event")
      end
    end

    context "when only timeline event's note was changed" do
      let(:was_changed) { :note }

      it 'posts the correct text to the system note' do
        expect(subject.note).to match("edited the text on incident timeline event")
      end
    end

    context "when both timeline events occurred_at and note was changed" do
      let(:was_changed) { :occurred_at_and_note }

      it 'posts the correct text to the system note' do
        expect(subject.note).to match("edited the event time/date and text on incident timeline event")
      end
    end

    context "when was changed reason is unknown" do
      let(:was_changed) { :unknown }

      it 'posts the correct text to the system note' do
        expect(subject.note).to match("edited incident timeline event")
      end
    end
  end

  describe '#delete_timeline_event' do
    subject { described_class.new(noteable: incident).delete_timeline_event(author) }

    it_behaves_like 'a system note' do
      let(:noteable) { incident }
      let(:action) { 'timeline_event' }
    end

    it 'posts the correct text to the system note' do
      expect(subject.note).to match('deleted an incident timeline event')
    end
  end
end

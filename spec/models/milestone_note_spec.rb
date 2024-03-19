# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestoneNote do
  describe '.from_event' do
    let(:author) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:noteable) { create(:issue, author: author, project: project) }
    let(:event) { create(:resource_milestone_event, issue: noteable) }

    subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

    it_behaves_like 'a synthetic note', 'milestone'

    context 'with a remove milestone event' do
      let(:milestone) { create(:milestone) }
      let(:event) { create(:resource_milestone_event, action: :remove, issue: noteable, milestone: milestone) }

      it 'creates the expected note' do
        reference = milestone.to_reference(noteable, format: :iid, full: true, absolute_path: true)

        expect(subject.note_html).to include('removed milestone')
        expect(subject.note_html).to include("data-original=\"#{reference}\"")
        expect(subject.note_html).not_to include('changed milestone to')
        expect(subject.created_at).to eq(event.created_at)
        expect(subject.updated_at).to eq(event.created_at)
      end
    end
  end
end

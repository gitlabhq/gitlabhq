require 'spec_helper'

describe Issuable::CommonSystemNotesService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issuable) { create(:issue) }

  describe '#execute' do
    it_behaves_like 'system note creation', { title: 'New title' }, 'changed title'
    it_behaves_like 'system note creation', { description: 'New description' }, 'changed the description'
    it_behaves_like 'system note creation', { discussion_locked: true }, 'locked this issue'
    it_behaves_like 'system note creation', { time_estimate: 5 }, 'changed time estimate'

    context 'when new label is added' do
      let(:label) { create(:label, project: project) }

      before do
        issuable.labels << label
        issuable.save
      end

      it 'creates a resource label event' do
        described_class.new(project, user).execute(issuable, [])
        event = issuable.reload.resource_label_events.last

        expect(event).not_to be_nil
        expect(event.label_id).to eq label.id
        expect(event.user_id).to eq user.id
      end
    end

    context 'when new milestone is assigned' do
      before do
        milestone = create(:milestone, project: project)
        issuable.milestone_id = milestone.id
      end

      it_behaves_like 'system note creation', {}, 'changed milestone'
    end

    context 'with merge requests WIP note' do
      context 'adding WIP note' do
        let(:issuable) { create(:merge_request, title: "merge request") }

        it_behaves_like 'system note creation', { title: "WIP merge request" }, 'marked as a **Work In Progress**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "WIP changed title")
          end

          it_behaves_like 'WIP notes creation', 'marked'
        end
      end

      context 'removing WIP note' do
        let(:issuable) { create(:merge_request, title: "WIP merge request") }

        it_behaves_like 'system note creation', { title: "merge request" }, 'unmarked as a **Work In Progress**'

        context 'and changing title' do
          before do
            issuable.update_attribute(:title, "changed title")
          end

          it_behaves_like 'WIP notes creation', 'unmarked'
        end
      end
    end
  end
end

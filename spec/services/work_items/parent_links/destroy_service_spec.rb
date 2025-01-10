# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::DestroyService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be(:parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item) }

    let(:parent_link_class) { WorkItems::ParentLink }

    subject { described_class.new(parent_link, user).execute }

    before_all do
      # Ensure support bot user is created so creation doesn't count towards query limit
      # and we don't try to obtain an exclusive lease within a transaction.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
      Users::Internal.support_bot_id
    end

    before do
      project.add_guest(guest)
    end

    context 'when user has permissions to update work items' do
      let(:user) { guest }

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        subject(:execute_service) { described_class.new(parent_link, user).execute }
      end

      it 'removes relation and creates notes', :aggregate_failures do
        expect { subject }
          .to change(parent_link_class, :count).by(-1)
          .and change(WorkItems::ResourceLinkEvent, :count).by(1)

        expect(work_item.notes.last.note).to eq("removed child task #{task.to_reference}")
        expect(task.notes.last.note).to eq("removed parent issue #{work_item.to_reference}")
        expect(WorkItems::ResourceLinkEvent.last).to have_attributes(
          user_id: user.id,
          issue_id: work_item.id,
          child_work_item_id: task.id,
          action: "remove",
          system_note_metadata_id: task.notes.last.system_note_metadata.id
        )
      end

      it 'returns success message' do
        is_expected.to eq(message: 'Relation was removed', status: :success)
      end

      context 'when note creation fails for some reason' do
        [Note.new, nil].each do |unrelate_child_note|
          it 'still records the link event', :aggregate_failures do
            allow(SystemNoteService).to receive(:unrelate_work_item).and_return(unrelate_child_note)

            expect { subject }
              .to change(WorkItems::ResourceLinkEvent, :count).by(1)
              .and not_change(Note, :count)

            expect(WorkItems::ResourceLinkEvent.last).to have_attributes(
              user_id: user.id,
              issue_id: work_item.id,
              child_work_item_id: task.id,
              action: "remove",
              system_note_metadata_id: nil
            )
          end
        end
      end
    end

    context 'when user has insufficient permissions' do
      let(:user) { create(:user) }

      it 'returns error message' do
        is_expected.to eq(message: 'No Work Item Link found', status: :error, http_status: 404)
      end

      it 'does not remove relation', :aggregate_failures do
        expect { subject }
          .to not_change(parent_link_class, :count).from(1)
          .and not_change(WorkItems::ResourceLinkEvent, :count)
        expect(SystemNoteService).not_to receive(:unrelate_work_item)
      end
    end
  end
end

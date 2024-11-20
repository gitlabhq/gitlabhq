# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussions::ResolveService, feature_category: :code_review_workflow do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, developer_of: project) }
    let_it_be(:merge_request) { create(:merge_request, :merge_when_checks_pass, source_project: project) }

    let(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }
    let(:service) { described_class.new(project, user, one_or_more_discussions: discussion) }

    it "doesn't resolve discussions the user can't resolve" do
      expect(discussion).to receive(:can_resolve?).with(user).and_return(false)

      service.execute

      expect(discussion).not_to be_resolved
    end

    it 'resolves the discussion' do
      service.execute

      expect(discussion).to be_resolved
    end

    it 'tracks thread resolve usage data' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_resolve_thread_action).with(user: user)

      service.execute
    end

    it 'executes the notification service' do
      expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
        expect(instance).to receive(:execute).with(discussion.noteable)
      end

      service.execute
    end

    context 'when all discussions are resolved' do
      it 'publishes the discussions resolved event' do
        expect { service.execute }
          .to publish_event(MergeRequests::DiscussionsResolvedEvent)
          .with(current_user_id: user.id, merge_request_id: merge_request.id)
      end
    end

    context 'when not all discussions are resolved' do
      let(:other_discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

      it 'does not publish the discussions resolved event' do
        expect { service.execute }.not_to publish_event(MergeRequests::DiscussionsResolvedEvent)
      end
    end

    it 'sends GraphQL triggers' do
      expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(discussion.noteable)

      service.execute
    end

    it 'adds a system note to the discussion' do
      issue = create(:issue, project: project)

      expect(SystemNoteService).to receive(:discussion_continued_in_issue).with(discussion, project, user, issue)
      service = described_class.new(project, user, one_or_more_discussions: discussion, follow_up_issue: issue)
      service.execute
    end

    it 'can resolve multiple discussions at once' do
      other_discussion = create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion
      service = described_class.new(project, user, one_or_more_discussions: [discussion, other_discussion])
      service.execute

      expect([discussion, other_discussion]).to all(be_resolved)
    end

    it 'raises an argument error if discussions do not belong to the same noteable' do
      other_merge_request = create(:merge_request)
      other_discussion = create(
        :diff_note_on_merge_request,
        noteable: other_merge_request,
        project: other_merge_request.source_project
      ).to_discussion
      expect do
        described_class.new(project, user, one_or_more_discussions: [discussion, other_discussion])
      end.to raise_error(
        ArgumentError,
        'Discussions must be all for the same noteable'
      )
    end

    context 'when discussion is not for a merge request' do
      let_it_be(:design) { create(:design, :with_file, issue: create(:issue, project: project)) }

      let(:discussion) { create(:diff_note_on_design, noteable: design, project: project).to_discussion }

      it 'does not execute the notification service' do
        expect(MergeRequests::ResolvedDiscussionNotificationService).not_to receive(:new)

        service.execute
      end

      it 'does not track thread resolve usage data' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_resolve_thread_action).with(user: user)

        service.execute
      end

      it 'does not publish the discussions resolved event' do
        expect { service.execute }.not_to publish_event(MergeRequests::DiscussionsResolvedEvent)
      end

      it 'does not send GraphQL triggers' do
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated).with(discussion.noteable)

        service.execute
      end
    end

    context 'when resolving a discussion' do
      def resolve_discussion(discussion, user)
        described_class.new(project, user, one_or_more_discussions: discussion).execute
      end

      context 'in a design' do
        let_it_be(:design) { create(:design, :with_file, issue: create(:issue, project: project)) }
        let_it_be(:user_1) { create(:user) }
        let_it_be(:user_2) { create(:user) }
        let_it_be(:discussion_1) { create(:diff_note_on_design, noteable: design, project: project, author: user_1).to_discussion }
        let_it_be(:discussion_2) { create(:diff_note_on_design, noteable: design, project: project, author: user_2).to_discussion }

        before do
          project.add_developer(user_1)
          project.add_developer(user_2)
        end

        context 'when user resolving discussion has open todos' do
          let!(:user_1_todo_for_discussion_1) { create(:todo, :pending, user: user_1, target: design, note: discussion_1.notes.first, project: project) }
          let!(:user_1_todo_2_for_discussion_1) { create(:todo, :pending, user: user_1, target: design, note: discussion_1.notes.first, project: project) }
          let!(:user_1_todo_for_discussion_2) { create(:todo, :pending, user: user_1, target: design, note: discussion_2.notes.first, project: project) }
          let!(:user_2_todo_for_discussion_1) { create(:todo, :pending, user: user_2, target: design, note: discussion_1.notes.first, project: project) }

          it 'marks user todos for given discussion as done' do
            resolve_discussion(discussion_1, user_1)

            expect(user_1_todo_for_discussion_1.reload).to be_done
            expect(user_1_todo_2_for_discussion_1.reload).to be_done
            expect(user_1_todo_for_discussion_2.reload).to be_pending
            expect(user_2_todo_for_discussion_1.reload).to be_pending
          end
        end
      end

      context 'in a merge request' do
        let!(:user_todo_for_discussion) { create(:todo, :pending, user: user, target: merge_request, note: discussion.notes.first, project: project) }

        it 'does not mark user todo as done' do
          resolve_discussion(discussion, user)

          expect(user_todo_for_discussion).to be_pending
        end
      end
    end
  end
end

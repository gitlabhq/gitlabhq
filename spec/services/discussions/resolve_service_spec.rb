# frozen_string_literal: true

require 'spec_helper'

describe Discussions::ResolveService do
  describe '#execute' do
    let(:discussion) { create(:diff_note_on_merge_request).to_discussion }
    let(:project) { merge_request.project }
    let(:merge_request) { discussion.noteable }
    let(:user) { create(:user) }
    let(:service) { described_class.new(discussion.noteable.project, user, merge_request: merge_request) }

    before do
      project.add_maintainer(user)
    end

    it "doesn't resolve discussions the user can't resolve" do
      expect(discussion).to receive(:can_resolve?).with(user).and_return(false)

      service.execute(discussion)

      expect(discussion.resolved?).to be(false)
    end

    it 'resolves the discussion' do
      service.execute(discussion)

      expect(discussion.resolved?).to be(true)
    end

    it 'executes the notification service' do
      expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
        expect(instance).to receive(:execute).with(discussion.noteable)
      end

      service.execute(discussion)
    end

    it 'adds a system note to the discussion' do
      issue = create(:issue, project: project)

      expect(SystemNoteService).to receive(:discussion_continued_in_issue).with(discussion, project, user, issue)
      service = described_class.new(project, user, merge_request: merge_request, follow_up_issue: issue)
      service.execute(discussion)
    end

    it 'can resolve multiple discussions at once' do
      other_discussion = create(:diff_note_on_merge_request, noteable: discussion.noteable, project: discussion.noteable.source_project).to_discussion

      service.execute([discussion, other_discussion])

      expect(discussion.resolved?).to be(true)
      expect(other_discussion.resolved?).to be(true)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::DuplicateService do
  let(:user) { create(:user) }
  let(:canonical_project) { create(:project) }
  let(:duplicate_project) { create(:project) }

  let(:canonical_issue) { create(:issue, project: canonical_project) }
  let(:duplicate_issue) { create(:issue, project: duplicate_project) }

  subject { described_class.new(project: duplicate_project, current_user: user) }

  describe '#execute' do
    context 'when the issues passed are the same' do
      it 'does nothing' do
        expect(subject).not_to receive(:close_service)
        expect(SystemNoteService).not_to receive(:mark_duplicate_issue)
        expect(SystemNoteService).not_to receive(:mark_canonical_issue_of_duplicate)

        subject.execute(duplicate_issue, duplicate_issue)
      end
    end

    context 'when the user cannot update the duplicate issue' do
      before do
        canonical_project.add_reporter(user)
      end

      it 'does nothing' do
        expect(subject).not_to receive(:close_service)
        expect(SystemNoteService).not_to receive(:mark_duplicate_issue)
        expect(SystemNoteService).not_to receive(:mark_canonical_issue_of_duplicate)

        subject.execute(duplicate_issue, canonical_issue)
      end
    end

    context 'when the user cannot comment on the canonical issue' do
      before do
        duplicate_project.add_reporter(user)
      end

      it 'does nothing' do
        expect(subject).not_to receive(:close_service)
        expect(SystemNoteService).not_to receive(:mark_duplicate_issue)
        expect(SystemNoteService).not_to receive(:mark_canonical_issue_of_duplicate)

        subject.execute(duplicate_issue, canonical_issue)
      end
    end

    context 'when the user can mark the issue as a duplicate' do
      before do
        canonical_project.add_reporter(user)
        duplicate_project.add_reporter(user)
      end

      it 'closes the duplicate issue' do
        subject.execute(duplicate_issue, canonical_issue)

        expect(duplicate_issue.reload).to be_closed
        expect(canonical_issue.reload).to be_open
      end

      it 'adds a system note to the duplicate issue' do
        expect(SystemNoteService)
          .to receive(:mark_duplicate_issue).with(duplicate_issue, duplicate_project, user, canonical_issue)

        subject.execute(duplicate_issue, canonical_issue)
      end

      it 'adds a system note to the canonical issue' do
        expect(SystemNoteService)
          .to receive(:mark_canonical_issue_of_duplicate).with(canonical_issue, canonical_project, user, duplicate_issue)

        subject.execute(duplicate_issue, canonical_issue)
      end

      it 'updates duplicate issue with canonical issue id' do
        subject.execute(duplicate_issue, canonical_issue)

        expect(duplicate_issue.reload.duplicated_to).to eq(canonical_issue)
      end

      it 'relates the duplicate issues' do
        canonical_project.add_reporter(user)
        duplicate_project.add_reporter(user)

        subject.execute(duplicate_issue, canonical_issue)

        issue_link = IssueLink.last
        expect(issue_link.source).to eq(duplicate_issue)
        expect(issue_link.target).to eq(canonical_issue)
      end
    end
  end
end

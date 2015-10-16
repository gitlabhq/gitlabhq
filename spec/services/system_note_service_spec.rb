require 'spec_helper'

describe SystemNoteService do
  let(:project)  { create(:project) }
  let(:author)   { create(:user) }
  let(:noteable) { create(:issue, project: project) }

  shared_examples_for 'a system note' do
    it 'is valid' do
      expect(subject).to be_valid
    end

    it 'sets the noteable model' do
      expect(subject.noteable).to eq noteable
    end

    it 'sets the project' do
      expect(subject.project).to eq project
    end

    it 'sets the author' do
      expect(subject.author).to eq author
    end

    it 'is a system note' do
      expect(subject).to be_system
    end
  end

  describe '.add_commits' do
    subject { described_class.add_commits(noteable, project, author, new_commits, old_commits, oldrev) }

    let(:noteable)    { create(:merge_request, source_project: project) }
    let(:new_commits) { noteable.commits }
    let(:old_commits) { [] }
    let(:oldrev)      { nil }

    it_behaves_like 'a system note'

    describe 'note body' do
      let(:note_lines) { subject.note.split("\n").reject(&:blank?) }

      context 'without existing commits' do
        it 'adds a message header' do
          expect(note_lines[0]).to eq "Added #{new_commits.size} commits:"
        end

        it 'adds a message line for each commit' do
          new_commits.each_with_index do |commit, i|
            # Skip the header
            expect(note_lines[i + 1]).to eq "* #{commit.short_id} - #{commit.title}"
          end
        end
      end

      describe 'summary line for existing commits' do
        let(:summary_line) { note_lines[1] }

        context 'with one existing commit' do
          let(:old_commits) { [noteable.commits.last] }

          it 'includes the existing commit' do
            expect(summary_line).to eq "* #{old_commits.first.short_id} - 1 commit from branch `feature`"
          end
        end

        context 'with multiple existing commits' do
          let(:old_commits) { noteable.commits[3..-1] }

          context 'with oldrev' do
            let(:oldrev) { noteable.commits[2].id }

            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{Commit.truncate_sha(oldrev)}...#{old_commits.last.short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 2 commits from branch `feature`"
            end
          end

          context 'without oldrev' do
            it 'includes a commit range' do
              expect(summary_line).to start_with "* #{old_commits[0].short_id}..#{old_commits[-1].short_id}"
            end

            it 'includes a commit count' do
              expect(summary_line).to end_with " - 2 commits from branch `feature`"
            end
          end

          context 'on a fork' do
            before do
              expect(noteable).to receive(:for_fork?).and_return(true)
            end

            it 'includes the project namespace' do
              expect(summary_line).to end_with "`#{noteable.target_project_namespace}:feature`"
            end
          end
        end
      end
    end
  end

  describe '.change_assignee' do
    subject { described_class.change_assignee(noteable, project, author, assignee) }

    let(:assignee) { create(:user) }

    it_behaves_like 'a system note'

    context 'when assignee added' do
      it 'sets the note text' do
        expect(subject.note).to eq "Reassigned to @#{assignee.username}"
      end
    end

    context 'when assignee removed' do
      let(:assignee) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'Assignee removed'
      end
    end
  end

  describe '.change_label' do
    subject { described_class.change_label(noteable, project, author, added, removed) }

    let(:labels)  { create_list(:label, 2) }
    let(:added)   { [] }
    let(:removed) { [] }

    it_behaves_like 'a system note'

    context 'with added labels' do
      let(:added)   { labels }
      let(:removed) { [] }

      it 'sets the note text' do
        expect(subject.note).to eq "Added ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with removed labels' do
      let(:added)   { [] }
      let(:removed) { labels }

      it 'sets the note text' do
        expect(subject.note).to eq "Removed ~#{labels[0].id} ~#{labels[1].id} labels"
      end
    end

    context 'with added and removed labels' do
      let(:added)   { [labels[0]] }
      let(:removed) { [labels[1]] }

      it 'sets the note text' do
        expect(subject.note).to eq "Added ~#{labels[0].id} and removed ~#{labels[1].id} labels"
      end
    end
  end

  describe '.change_milestone' do
    subject { described_class.change_milestone(noteable, project, author, milestone) }

    let(:milestone) { create(:milestone, project: project) }

    it_behaves_like 'a system note'

    context 'when milestone added' do
      it 'sets the note text' do
        expect(subject.note).to eq "Milestone changed to #{milestone.title}"
      end
    end

    context 'when milestone removed' do
      let(:milestone) { nil }

      it 'sets the note text' do
        expect(subject.note).to eq 'Milestone removed'
      end
    end
  end

  describe '.change_status' do
    subject { described_class.change_status(noteable, project, author, status, source) }

    let(:status) { 'new_status' }
    let(:source) { nil }

    it_behaves_like 'a system note'

    context 'with a source' do
      let(:source) { double('commit', gfm_reference: 'commit 123456') }

      it 'sets the note text' do
        expect(subject.note).to eq "Status changed to #{status} by commit 123456"
      end
    end

    context 'without a source' do
      it 'sets the note text' do
        expect(subject.note).to eq "Status changed to #{status}"
      end
    end
  end

  describe '.change_title' do
    subject { described_class.change_title(noteable, project, author, 'Old title') }

    context 'when noteable responds to `title`' do
      it_behaves_like 'a system note'

      it 'sets the note text' do
        expect(subject.note).
          to eq "Title changed from **Old title** to **#{noteable.title}**"
      end
    end

    context 'when noteable does not respond to `title' do
      let(:noteable) { double('noteable') }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.change_branch' do
    subject { described_class.change_branch(noteable, project, author, 'target', old_branch, new_branch) }
    let(:old_branch) { 'old_branch'}
    let(:new_branch) { 'new_branch'}

    it_behaves_like 'a system note'

    context 'when target branch name changed' do
      it 'sets the note text' do
        expect(subject.note).to eq "Target branch changed from `#{old_branch}` to `#{new_branch}`"
      end
    end
  end

  describe '.change_branch_presence' do
    subject { described_class.change_branch_presence(noteable, project, author, :source, 'feature', :delete) }

    it_behaves_like 'a system note'

    context 'when source branch deleted' do
      it 'sets the note text' do
        expect(subject.note).to eq "Deleted source branch `feature`"
      end
    end
  end

  describe '.cross_reference' do
    subject { described_class.cross_reference(noteable, mentioner, author) }

    let(:mentioner) { create(:issue, project: project) }

    it_behaves_like 'a system note'

    context 'when cross-reference disallowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(true)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when cross-reference allowed' do
      before do
        expect(described_class).to receive(:cross_reference_disallowed?).and_return(false)
      end

      describe 'note_body' do
        context 'cross-project' do
          let(:project2)  { create(:project) }
          let(:mentioner) { create(:issue, project: project2) }

          context 'from Commit' do
            let(:mentioner) { project2.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference(project)}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference(project)}"
            end
          end
        end

        context 'within the same project' do
          context 'from Commit' do
            let(:mentioner) { project.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference}"
            end
          end
        end
      end
    end
  end

  describe '.cross_reference?' do
    it 'is truthy when text begins with expected text' do
      expect(described_class.cross_reference?('mentioned in something')).to be_truthy
    end

    it 'is falsey when text does not begin with expected text' do
      expect(described_class.cross_reference?('this is a note')).to be_falsey
    end
  end

  describe '.cross_reference_disallowed?' do
    context 'when mentioner is not a MergeRequest' do
      it 'is falsey' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_falsey
      end
    end

    context 'when mentioner is a MergeRequest' do
      let(:mentioner) { create(:merge_request, :simple, source_project: project) }
      let(:noteable)  { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioner).to receive(:commits).and_return([noteable])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_truthy
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioner).to receive(:commits).and_return([])
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_falsey
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }
      it 'is truthy' do
        mentioner = noteable.dup
        expect(described_class.cross_reference_disallowed?(noteable, mentioner)).
          to be_truthy
      end
    end
  end

  describe '.cross_reference_exists?' do
    let(:commit0) { project.commit }
    let(:commit1) { project.commit('HEAD~2') }

    context 'issue from commit' do
      before do
        # Mention issue (noteable) from commit0
        described_class.cross_reference(noteable, commit0, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit0)).
          to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(noteable, commit1)).
          to be_falsey
      end
    end

    context 'commit from commit' do
      before do
        # Mention commit1 from commit0
        described_class.cross_reference(commit0, commit1, author)
      end

      it 'is truthy when already mentioned' do
        expect(described_class.cross_reference_exists?(commit0, commit1)).
          to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(described_class.cross_reference_exists?(commit1, commit0)).
          to be_falsey
      end
    end
  end
end

require 'spec_helper'

describe Issues::MoveService do
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  let(:title) { 'Some issue' }
  let(:description) { 'Some issue description' }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project, group: create(:group)) }
  let(:milestone1) { create(:milestone, project_id: old_project.id, title: 'v9.0') }

  let(:old_issue) do
    create(:issue, title: title, description: description,
                   project: old_project, author: author, milestone: milestone1)
  end

  let(:move_service) do
    described_class.new(old_project, user)
  end

  shared_context 'user can move issue' do
    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)

      labels = Array.new(2) { |x| "label%d" % (x + 1) }

      labels.each do |label|
        old_issue.labels << create(:label,
          project_id: old_project.id,
          title: label)

        new_project.labels << create(:label, title: label)
      end
    end
  end

  describe '#execute' do
    shared_context 'issue move executed' do
      let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

      let!(:new_issue) { move_service.execute(old_issue, new_project) }
    end

    context 'issue movable' do
      include_context 'user can move issue'

      context 'move to new milestone'  do
        let(:new_issue) { move_service.execute(old_issue, new_project) }

        context 'project milestone' do
          let!(:milestone2) do
            create(:milestone, project_id: new_project.id, title: 'v9.0')
          end

          it 'assigns milestone to new issue' do
            expect(new_issue.reload.milestone.title).to eq 'v9.0'
            expect(new_issue.reload.milestone).to eq(milestone2)
          end
        end

        context 'group milestones' do
          let!(:group) { create(:group, :private) }
          let!(:group_milestone_1) do
            create(:milestone, group_id: group.id, title: 'v9.0_group')
          end

          before do
            old_issue.update(milestone: group_milestone_1)
            old_project.update(namespace: group)
            new_project.update(namespace: group)

            group.add_users([user], GroupMember::DEVELOPER)
          end

          context 'when moving to a project of the same group' do
            it 'keeps the same group milestone' do
              expect(new_issue.reload.project).to eq(new_project)
              expect(new_issue.reload.milestone).to eq(group_milestone_1)
            end
          end

          context 'when moving to a project of a different group' do
            let!(:group_2) { create(:group, :private) }

            let!(:group_milestone_2) do
              create(:milestone, group_id: group_2.id, title: 'v9.0_group')
            end

            before do
              old_issue.update(milestone: group_milestone_1)
              new_project.update(namespace: group_2)

              group_2.add_users([user], GroupMember::DEVELOPER)
            end

            it 'assigns to new group milestone of same title' do
              expect(new_issue.reload.project).to eq(new_project)
              expect(new_issue.reload.milestone).to eq(group_milestone_2)
            end
          end
        end
      end

      context 'generic issue' do
        include_context 'issue move executed'

        it 'creates a new issue in a new project' do
          expect(new_issue.project).to eq new_project
        end

        it 'assign labels to new issue' do
          expected_label_titles = new_issue.reload.labels.map(&:title)
          expect(expected_label_titles).to include 'label1'
          expect(expected_label_titles).to include 'label2'
          expect(expected_label_titles.size).to eq 2

          new_issue.labels.each do |label|
            expect(new_project.labels).to include(label)
            expect(old_project.labels).not_to include(label)
          end
        end

        it 'rewrites issue title' do
          expect(new_issue.title).to eq title
        end

        it 'rewrites issue description' do
          expect(new_issue.description).to eq description
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'moved to'
        end

        it 'adds system note to new issue at the end' do
          expect(new_issue.notes.last.note).to start_with 'moved from'
        end

        it 'closes old issue' do
          expect(old_issue.closed?).to be true
        end

        it 'persists new issue' do
          expect(new_issue.persisted?).to be true
        end

        it 'persists all changes' do
          expect(old_issue.changed?).to be false
          expect(new_issue.changed?).to be false
        end

        it 'preserves author' do
          expect(new_issue.author).to eq author
        end

        it 'creates a new internal id for issue' do
          expect(new_issue.iid).to be 1
        end

        it 'marks issue as moved' do
          expect(old_issue.moved?).to eq true
          expect(old_issue.moved_to).to eq new_issue
        end

        it 'preserves create time' do
          expect(old_issue.created_at).to eq new_issue.created_at
        end

        it 'moves the award emoji' do
          expect(old_issue.award_emoji.first.name).to eq new_issue.reload.award_emoji.first.name
        end
      end

      context 'issue with notes' do
        context 'notes without references' do
          let(:notes_params) do
            [{ system: false, note: 'Some comment 1' },
             { system: true, note: 'Some system note' },
             { system: false, note: 'Some comment 2' }]
          end
          let(:award_names) { %w(thumbsup thumbsdown facepalm) }
          let(:notes_contents) { notes_params.map { |n| n[:note] } }

          before do
            note_params = { noteable: old_issue, project: old_project, author: author }
            notes_params.each_with_index do |note, index|
              new_note = create(:note, note_params.merge(note))
              award_emoji_params = { awardable: new_note, name: award_names[index] }
              create(:award_emoji, award_emoji_params)
            end
          end

          include_context 'issue move executed'

          let(:all_notes) { new_issue.notes.order('id ASC') }
          let(:system_notes) { all_notes.system }
          let(:user_notes) { all_notes.user }

          it 'rewrites existing notes in valid order' do
            expect(all_notes.pluck(:note).first(3)).to eq notes_contents
          end

          it 'creates new emojis for the new notes' do
            expect(all_notes.map(&:award_emoji).to_a.flatten.map(&:name)).to eq award_names
          end

          it 'adds a system note about move after rewritten notes' do
            expect(system_notes.last.note).to match /^moved from/
          end

          it 'preserves orignal author of comment' do
            expect(user_notes.pluck(:author_id)).to all(eq(author.id))
          end
        end

        context 'note that has been updated' do
          let!(:note) do
            create(:note, noteable: old_issue, project: old_project,
                          author: author, updated_at: Date.yesterday,
                          created_at: Date.yesterday)
          end

          include_context 'issue move executed'

          it 'preserves time when note has been created at' do
            expect(new_issue.notes.first.created_at).to eq note.created_at
          end

          it 'preserves time when note has been updated at' do
            expect(new_issue.notes.first.updated_at).to eq note.updated_at
          end
        end

        context 'issue with assignee' do
          let(:assignee) { create(:user) }

          before do
            old_issue.assignees = [assignee]
          end

          it 'preserves assignee with access to the new issue' do
            new_project.add_reporter(assignee)

            new_issue = move_service.execute(old_issue, new_project)

            expect(new_issue.assignees).to eq([assignee])
          end

          it 'ignores assignee without access to the new issue' do
            new_issue = move_service.execute(old_issue, new_project)

            expect(new_issue.assignees).to be_empty
          end
        end

        context 'notes with references' do
          before do
            create(:merge_request, source_project: old_project)
            create(:note, noteable: old_issue, project: old_project, author: author,
                          note: 'Note with reference to merge request !1')
          end

          include_context 'issue move executed'
          let(:new_note) { new_issue.notes.first }

          it 'rewrites references using a cross reference to old project' do
            expect(new_note.note)
              .to eq "Note with reference to merge request #{old_project.to_reference(new_project)}!1"
          end
        end

        context 'issue description with uploads' do
          let(:uploader) { build(:file_uploader, project: old_project) }
          let(:description) { "Text and #{uploader.markdown_link}" }

          include_context 'issue move executed'

          it 'rewrites uploads in description' do
            expect(new_issue.description).not_to eq description
            expect(new_issue.description)
              .to match(/Text and #{FileUploader::MARKDOWN_PATTERN}/)
            expect(new_issue.description).not_to include uploader.secret
          end
        end
      end

      describe 'rewriting references' do
        include_context 'issue move executed'

        context 'issue references' do
          let(:another_issue) { create(:issue, project: old_project) }
          let(:description) { "Some description #{another_issue.to_reference}" }

          it 'rewrites referenced issues creating cross project reference' do
            expect(new_issue.description)
              .to eq "Some description #{another_issue.to_reference(new_project)}"
          end
        end

        context "user references" do
          let(:another_issue) { create(:issue, project: old_project) }
          let(:description) { "Some description #{user.to_reference}" }

          it "doesn't throw any errors for issues containing user references" do
            expect(new_issue.description)
              .to eq "Some description #{user.to_reference}"
          end
        end
      end

      context 'moving to same project' do
        let(:new_project) { old_project }

        it 'raises error' do
          expect { move_service.execute(old_issue, new_project) }
            .to raise_error(StandardError, /Cannot move issue/)
        end
      end

      context 'project issue hooks' do
        let!(:hook) { create(:project_hook, project: old_project, issues_events: true) }

        it 'executes project issue hooks' do
          allow_any_instance_of(WebHookService).to receive(:execute)

          # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
          # but since the entire spec run takes place in a transaction, we never
          # actually get to the `after_commit` hook that queues these jobs.
          expect { move_service.execute(old_issue, new_project) }
            .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
        end
      end
    end

    describe 'move permissions' do
      let(:move) { move_service.execute(old_issue, new_project) }

      context 'user is reporter in both projects' do
        include_context 'user can move issue'
        it { expect { move }.not_to raise_error }
      end

      context 'user is reporter only in new project' do
        before do
          new_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter only in old project' do
        before do
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter in one project and guest in another' do
        before do
          new_project.add_guest(user)
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue has already been moved' do
        include_context 'user can move issue'

        let(:moved_to_issue) { create(:issue) }

        let(:old_issue) do
          create(:issue, project: old_project, author: author,
                         moved_to: moved_to_issue)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue is not persisted' do
        include_context 'user can move issue'
        let(:old_issue) { build(:issue, project: old_project, author: author) }
        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end
    end

    context 'movable issue with no assigned labels' do
      before do
        old_project.add_reporter(user)
        new_project.add_reporter(user)

        labels = Array.new(2) { |x| "label%d" % (x + 1) }

        labels.each do |label|
          new_project.labels << create(:label, title: label)
        end
      end

      include_context 'issue move executed'

      it 'does not assign labels to new issue' do
        expected_label_titles = new_issue.reload.labels.map(&:title)
        expect(expected_label_titles.size).to eq 0
      end
    end
  end
end

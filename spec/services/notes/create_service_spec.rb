require 'spec_helper'

describe Notes::CreateService do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }
  let(:opts) do
    { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id }
  end

  describe '#execute' do
    before do
      project.add_maintainer(user)
    end

    context "valid params" do
      it 'returns a valid note' do
        note = described_class.new(project, user, opts).execute

        expect(note).to be_valid
      end

      it 'returns a persisted note' do
        note = described_class.new(project, user, opts).execute

        expect(note).to be_persisted
      end

      it 'note has valid content' do
        note = described_class.new(project, user, opts).execute

        expect(note.note).to eq(opts[:note])
      end

      it 'note belongs to the correct project' do
        note = described_class.new(project, user, opts).execute

        expect(note.project).to eq(project)
      end

      it 'TodoService#new_note is called' do
        note = build(:note, project: project)
        allow(Note).to receive(:new).with(opts) { note }

        expect_any_instance_of(TodoService).to receive(:new_note).with(note, user)

        described_class.new(project, user, opts).execute
      end

      it 'enqueues NewNoteWorker' do
        note = build(:note, id: 999, project: project)
        allow(Note).to receive(:new).with(opts) { note }

        expect(NewNoteWorker).to receive(:perform_async).with(note.id)

        described_class.new(project, user, opts).execute
      end
    end

    context 'note diff file' do
      let(:project_with_repo) { create(:project, :repository) }
      let(:merge_request) do
        create(:merge_request,
               source_project: project_with_repo,
               target_project: project_with_repo)
      end
      let(:line_number) { 14 }
      let(:position) do
        Gitlab::Diff::Position.new(old_path: "files/ruby/popen.rb",
                                   new_path: "files/ruby/popen.rb",
                                   old_line: nil,
                                   new_line: line_number,
                                   diff_refs: merge_request.diff_refs)
      end
      let(:previous_note) do
        create(:diff_note_on_merge_request, noteable: merge_request, project: project_with_repo)
      end

      context 'when eligible to have a note diff file' do
        let(:new_opts) do
          opts.merge(in_reply_to_discussion_id: nil,
                     type: 'DiffNote',
                     noteable_type: 'MergeRequest',
                     noteable_id: merge_request.id,
                     position: position.to_h)
        end

        it 'note is associated with a note diff file' do
          note = described_class.new(project_with_repo, user, new_opts).execute

          expect(note).to be_persisted
          expect(note.note_diff_file).to be_present
        end
      end

      context 'when DiffNote is a reply' do
        let(:new_opts) do
          opts.merge(in_reply_to_discussion_id: previous_note.discussion_id,
                     type: 'DiffNote',
                     noteable_type: 'MergeRequest',
                     noteable_id: merge_request.id,
                     position: position.to_h)
        end

        it 'note is not associated with a note diff file' do
          note = described_class.new(project_with_repo, user, new_opts).execute

          expect(note).to be_persisted
          expect(note.note_diff_file).to be_nil
        end

        context 'when DiffNote from an image' do
          let(:image_position) do
            Gitlab::Diff::Position.new(old_path: "files/images/6049019_460s.jpg",
                                       new_path: "files/images/6049019_460s.jpg",
                                       width: 100,
                                       height: 100,
                                       x: 1,
                                       y: 100,
                                       diff_refs: merge_request.diff_refs,
                                       position_type: 'image')
          end

          let(:new_opts) do
            opts.merge(in_reply_to_discussion_id: nil,
                       type: 'DiffNote',
                       noteable_type: 'MergeRequest',
                       noteable_id: merge_request.id,
                       position: image_position.to_h)
          end

          it 'note is not associated with a note diff file' do
            note = described_class.new(project_with_repo, user, new_opts).execute

            expect(note).to be_persisted
            expect(note.note_diff_file).to be_nil
          end
        end
      end
    end

    context 'note with commands' do
      context 'as a user who can update the target' do
        context '/close, /label, /assign & /milestone' do
          let(:note_text) { %(HELLO\n/close\n/assign @#{user.username}\nWORLD) }

          it 'saves the note and does not alter the note text' do
<<<<<<< HEAD
            service = instance_double('Issues::UpdateService', :service)

            allow(Issues::UpdateService).to receive(:new).and_return(service)

=======
            service = double(:service)
            allow(Issues::UpdateService).to receive(:new).and_return(service)
>>>>>>> upstream/master
            expect(service).to receive(:execute)

            note = described_class.new(project, user, opts.merge(note: note_text)).execute

            expect(note.note).to eq "HELLO\nWORLD"
          end
        end

        context '/merge with sha option' do
          let(:note_text) { %(HELLO\n/merge\nWORLD) }
          let(:params) { opts.merge(note: note_text, merge_request_diff_head_sha: 'sha') }

          it 'saves the note and exectues merge command' do
            note = described_class.new(project, user, params).execute

            expect(note.note).to eq "HELLO\nWORLD"
          end
        end
      end

      context 'as a user who cannot update the target' do
        let(:note_text) { "HELLO\n/todo\n/assign #{user.to_reference}\nWORLD" }
        let(:note) { described_class.new(project, user, opts.merge(note: note_text)).execute }

        before do
          project.team.find_member(user.id).update!(access_level: Gitlab::Access::GUEST)
        end

        it 'applies commands the user can execute' do
          expect { note }.to change { user.todos_pending_count }.from(0).to(1)
        end

        it 'does not apply commands the user cannot execute' do
          expect { note }.not_to change { issue.assignees }
        end

        it 'saves the note' do
          expect(note.note).to eq "HELLO\nWORLD"
        end
      end
    end

    context 'personal snippet note' do
      subject { described_class.new(nil, user, params).execute }

      let(:snippet) { create(:personal_snippet) }
      let(:params) do
        { note: 'comment', noteable_type: 'Snippet', noteable_id: snippet.id }
      end

      it 'returns a valid note' do
        expect(subject).to be_valid
      end

      it 'returns a persisted note' do
        expect(subject).to be_persisted
      end

      it 'note has valid content' do
        expect(subject.note).to eq(params[:note])
      end
    end

    context 'note with emoji only' do
      it 'creates regular note' do
        opts = {
          note: ':smile: ',
          noteable_type: 'Issue',
          noteable_id: issue.id
        }
        note = described_class.new(project, user, opts).execute

        expect(note).to be_valid
        expect(note.note).to eq(':smile:')
      end
    end
  end
end

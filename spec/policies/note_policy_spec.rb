# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotePolicy, feature_category: :team_planning do
  describe '#rules', :aggregate_failures do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }
    let(:noteable) { issue }
    let(:policy) { described_class.new(user, note) }
    let(:note) { create(:note, noteable: noteable, author: user, project: project) }

    shared_examples_for 'user cannot read or act on the note' do
      specify do
        expect(policy).to be_disallowed(:admin_note, :reposition_note, :resolve_note, :read_note, :award_emoji)
      end
    end

    shared_examples_for 'a discussion with a private noteable' do
      context 'when the note author can no longer see the noteable' do
        it_behaves_like 'user cannot read or act on the note'
      end

      context 'when the note author can still see the noteable' do
        before do
          project.add_developer(user)
        end

        it 'can edit the note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:reposition_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:award_emoji)
        end
      end
    end

    shared_examples_for 'a note on a public noteable' do
      it 'can only read and award emoji on the note' do
        expect(policy).to be_allowed(:read_note, :award_emoji)
        expect(policy).to be_disallowed(:reposition_note, :admin_note, :resolve_note)
      end
    end

    context 'when the noteable is a deleted commit' do
      let(:commit) { nil }
      let(:note) { create(:note_on_commit, commit_id: '12345678', author: user, project: project) }

      it 'allows to read' do
        expect(policy).to be_allowed(:read_note)
        expect(policy).to be_disallowed(:admin_note)
        expect(policy).to be_disallowed(:reposition_note)
        expect(policy).to be_disallowed(:resolve_note)
        expect(policy).to be_disallowed(:award_emoji)
      end
    end

    context 'when the noteable is a commit' do
      let(:commit) { project.repository.head_commit }
      let(:note) { create(:note_on_commit, commit_id: commit.id, author: user, project: project) }

      context 'when the project is private' do
        let(:project) { create(:project, :private, :repository) }

        it_behaves_like 'a discussion with a private noteable'
      end

      context 'when the project is public' do
        context 'when repository access level is private' do
          let(:project) { create(:project, :public, :repository, :repository_private) }

          it_behaves_like 'a discussion with a private noteable'
        end
      end
    end

    context 'when the noteable is a Design' do
      include DesignManagementTestHelpers

      let(:note) { create(:note, noteable: noteable, project: project) }
      let(:noteable) { create(:design, issue: issue) }

      before do
        enable_design_management
      end

      it 'can read, award emoji and reposition the note' do
        expect(policy).to be_allowed(:reposition_note, :read_note, :award_emoji)
        expect(policy).to be_disallowed(:admin_note, :resolve_note)
      end

      context 'when project is private' do
        let(:project) { create(:project, :private) }

        it_behaves_like 'user cannot read or act on the note'
      end
    end

    context 'when the noteable is a personal snippet' do
      let(:noteable) { create(:personal_snippet, :public) }
      let(:other_user) { create(:user) }
      let(:note) { create(:note_on_personal_snippet, noteable: noteable) }

      it_behaves_like 'a note on a public noteable'

      context 'when user is the author of the personal snippet' do
        let(:noteable) { create(:personal_snippet, :public, author: user) }
        let(:note) { create(:note_on_personal_snippet, noteable: noteable, author: user) }

        it 'can edit note' do
          expect(policy).to be_allowed(:read_note, :award_emoji, :admin_note, :reposition_note, :resolve_note)
        end

        context 'when the note is private' do
          let(:noteable) { create(:personal_snippet, :private) }

          it_behaves_like 'user cannot read or act on the note'
        end

        context 'when the note is authored by another user' do
          let(:note) { create(:note_on_personal_snippet, noteable: noteable, author: other_user) }

          it 'can edit note' do
            expect(policy).to be_allowed(:read_note, :award_emoji, :admin_note, :reposition_note, :resolve_note)
          end
        end
      end

      context 'when the user is admin' do
        let(:admin) { create(:admin) }
        let(:policy) { described_class.new(admin, note) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'can edit note made by other users' do
            expect(policy).to be_allowed(:read_note, :award_emoji, :admin_note, :reposition_note, :resolve_note)
          end
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'a note on a public noteable'

          context 'when the note is private' do
            let(:noteable) { create(:personal_snippet, :private) }

            it_behaves_like 'user cannot read or act on the note'
          end
        end
      end
    end

    context 'when the project is public' do
      context 'when user is not the author of the note' do
        let(:note) { create(:note, noteable: noteable, project: project) }

        it_behaves_like 'a note on a public noteable'
      end

      context 'when the note author is not a project member' do
        it 'can edit a note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:reposition_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
        end
      end

      context 'when the noteable is a project snippet' do
        let(:noteable) { create(:project_snippet, :public, project: project) }

        it 'can edit note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:reposition_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
        end

        context 'when it is private' do
          let(:noteable) { create(:project_snippet, :private, project: project) }

          it_behaves_like 'a discussion with a private noteable'
        end
      end

      context 'when a discussion is confidential' do
        before do
          issue.update_attribute(:confidential, true)
        end

        it_behaves_like 'a discussion with a private noteable'
      end

      context 'when a discussion is locked' do
        before do
          issue.update_attribute(:discussion_locked, true)
        end

        context 'when the note author is a project member' do
          before do
            project.add_developer(user)
          end

          it 'can edit a note' do
            expect(policy).to be_allowed(:admin_note)
            expect(policy).to be_allowed(:reposition_note)
            expect(policy).to be_allowed(:resolve_note)
            expect(policy).to be_allowed(:read_note)
          end
        end

        context 'when the note author is not a project member' do
          it 'can not edit a note' do
            expect(policy).to be_disallowed(:admin_note)
            expect(policy).to be_disallowed(:reposition_note)
            expect(policy).to be_disallowed(:resolve_note)
          end

          it 'can read a note' do
            expect(policy).to be_allowed(:read_note)
          end
        end
      end

      context 'for discussions' do
        let(:policy) { described_class.new(user, note.discussion) }

        it 'allows the author to manage the discussion' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:reposition_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:award_emoji)
        end

        context 'when the user does not have access to the noteable' do
          before do
            noteable.update_attribute(:confidential, true)
          end

          it_behaves_like 'a discussion with a private noteable'
        end
      end

      context 'when it is a system note' do
        let(:developer) { create(:user) }
        let(:any_user) { create(:user) }

        shared_examples_for 'user can read the note' do
          it 'allows the user to read the note' do
            expect(policy).to be_allowed(:read_note)
          end
        end

        shared_examples_for 'user can act on the note' do
          it 'allows the user to read the note' do
            expect(policy).to be_disallowed(:admin_note)
            expect(policy).to be_disallowed(:reposition_note)
            expect(policy).to be_allowed(:resolve_note)
            expect(policy).to be_allowed(:award_emoji)
          end
        end

        context 'when noteable is a public issue' do
          let(:note) { create(:note, system: true, noteable: noteable, author: user, project: project) }

          before do
            project.add_developer(developer)
          end

          context 'when user is project member' do
            let(:policy) { described_class.new(developer, note) }

            it_behaves_like 'user can read the note'
            it_behaves_like 'user can act on the note'
          end

          context 'when user is not project member' do
            let(:policy) { described_class.new(any_user, note) }

            it_behaves_like 'user can read the note'
          end

          context 'when user is anonymous' do
            let(:policy) { described_class.new(nil, note) }

            it_behaves_like 'user can read the note'
          end

          context 'when notes widget is disabled for task' do
            let(:policy) { described_class.new(developer, note) }

            before do
              WorkItems::Type.default_by_type(:task).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
            end

            context 'when noteable is task' do
              let(:noteable) { create(:work_item, :task, project: project) }
              let(:note) { create(:note, system: true, noteable: noteable, author: user, project: project) }

              it_behaves_like 'user cannot read or act on the note'
            end

            context 'when noteable is issue' do
              let(:noteable) { create(:work_item, project: project) }
              let(:note) { create(:note, system: true, noteable: noteable, author: user, project: project) }

              it_behaves_like 'user can read the note'
              it_behaves_like 'user can act on the note'
            end
          end
        end

        context 'when it is a system note referencing a confidential issue' do
          let(:confidential_issue) { create(:issue, :confidential, project: project) }
          let(:note) { create(:note, system: true, noteable: issue, author: user, project: project, note: "mentioned in issue #{confidential_issue.to_reference(project)}") }

          before do
            project.add_developer(developer)
          end

          context 'when user is project member' do
            let(:policy) { described_class.new(developer, note) }

            it_behaves_like 'user can read the note'
            it_behaves_like 'user can act on the note'
          end

          context 'when user is not project member' do
            let(:policy) { described_class.new(any_user, note) }

            it_behaves_like 'user cannot read or act on the note'
          end

          context 'when user is anonymous' do
            let(:policy) { described_class.new(nil, note) }

            it_behaves_like 'user cannot read or act on the note'
          end
        end
      end

      context 'with internal notes' do
        def permissions(user, note)
          described_class.new(user, note)
        end

        let(:reporter) { create(:user) }
        let(:developer) { create(:user) }
        let(:maintainer) { create(:user) }
        let(:guest) { create(:user) }
        let(:non_member) { create(:user) }
        let(:author) { create(:user) }
        let(:assignee) { create(:user) }
        let(:admin) { create(:admin) }

        before do
          project.add_reporter(reporter)
          project.add_developer(developer)
          project.add_maintainer(maintainer)
          project.add_guest(guest)
        end

        shared_examples_for 'internal notes permissions' do
          it 'does not allow non members to read internal notes and replies' do
            expect(permissions(non_member, internal_note)).to be_disallowed(:read_note, :admin_note, :reposition_note, :resolve_note, :award_emoji, :mark_note_as_internal)
          end

          it 'does not allow guests to read internal notes and replies' do
            expect(permissions(guest, internal_note)).to be_disallowed(:read_note, :read_internal_note, :admin_note, :reposition_note, :resolve_note, :award_emoji, :mark_note_as_internal)
          end

          it 'allows reporter to read all notes but not resolve and admin them' do
            expect(permissions(reporter, internal_note)).to be_allowed(:read_note, :award_emoji, :mark_note_as_internal)
            expect(permissions(reporter, internal_note)).to be_disallowed(:admin_note, :reposition_note, :resolve_note)
          end

          it 'allows developer to read and resolve all notes' do
            expect(permissions(developer, internal_note)).to be_allowed(:read_note, :award_emoji, :resolve_note, :mark_note_as_internal)
            expect(permissions(developer, internal_note)).to be_disallowed(:admin_note, :reposition_note)
          end

          it 'allows maintainers to read all notes and admin them' do
            expect(permissions(maintainer, internal_note)).to be_allowed(:read_note, :admin_note, :reposition_note, :resolve_note, :award_emoji, :mark_note_as_internal)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it 'allows admins to read all notes and admin them' do
              expect(permissions(admin, internal_note)).to be_allowed(:read_note, :admin_note, :reposition_note, :resolve_note, :award_emoji, :mark_note_as_internal)
            end
          end

          context 'when admin mode is disabled' do
            it 'does not allow non members to read internal notes and replies' do
              expect(permissions(admin, internal_note)).to be_disallowed(:read_note, :admin_note, :reposition_note, :resolve_note, :award_emoji, :mark_note_as_internal)
            end
          end

          it 'disallows noteable author to read and resolve all notes' do
            expect(permissions(author, internal_note)).to be_disallowed(:read_note, :resolve_note, :award_emoji, :mark_note_as_internal, :admin_note, :reposition_note)
          end
        end

        context 'for issues' do
          let(:issue) { create(:issue, project: project, author: author, assignees: [assignee]) }
          let(:internal_note) { create(:note, :confidential, project: project, noteable: issue) }

          it_behaves_like 'internal notes permissions'

          it 'disallows noteable assignees to read all notes' do
            expect(permissions(assignee, internal_note)).to be_disallowed(:read_note, :award_emoji, :mark_note_as_internal, :admin_note, :reposition_note, :resolve_note)
          end
        end
      end
    end
  end
end

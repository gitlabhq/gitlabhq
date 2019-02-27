require 'spec_helper'

describe NotePolicy do
  describe '#rules' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }
    let(:noteable) { issue }
    let(:policy) { described_class.new(user, note) }
    let(:note) { create(:note, noteable: noteable, author: user, project: project) }

    shared_examples_for 'a discussion with a private noteable' do
      context 'when the note author can no longer see the noteable' do
        it 'can not edit nor read the note' do
          expect(policy).to be_disallowed(:admin_note)
          expect(policy).to be_disallowed(:resolve_note)
          expect(policy).to be_disallowed(:read_note)
          expect(policy).to be_disallowed(:award_emoji)
        end
      end

      context 'when the note author can still see the noteable' do
        before do
          project.add_developer(user)
        end

        it 'can edit the note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:award_emoji)
        end
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

    context 'when the project is public' do
      context 'when the note author is not a project member' do
        it 'can edit a note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
        end
      end

      context 'when the noteable is a project snippet' do
        let(:noteable) { create(:project_snippet, :public, project: project) }

        it 'can edit note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
        end

        context 'when it is private' do
          let(:noteable) { create(:project_snippet, :private, project: project) }

          it_behaves_like 'a discussion with a private noteable'
        end
      end

      context 'when the noteable is a personal snippet' do
        let(:noteable) { create(:personal_snippet, :public) }

        it 'can edit note' do
          expect(policy).to be_allowed(:admin_note)
          expect(policy).to be_allowed(:resolve_note)
          expect(policy).to be_allowed(:read_note)
        end

        context 'when it is private' do
          let(:noteable) { create(:personal_snippet, :private) }

          it 'can not edit nor read the note' do
            expect(policy).to be_disallowed(:admin_note)
            expect(policy).to be_disallowed(:resolve_note)
            expect(policy).to be_disallowed(:read_note)
          end
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
            expect(policy).to be_allowed(:resolve_note)
            expect(policy).to be_allowed(:read_note)
          end
        end

        context 'when the note author is not a project member' do
          it 'can not edit a note' do
            expect(policy).to be_disallowed(:admin_note)
            expect(policy).to be_disallowed(:resolve_note)
          end

          it 'can read a note' do
            expect(policy).to be_allowed(:read_note)
          end
        end
      end
    end
  end
end

require 'spec_helper'

describe NotePolicy, mdoels: true do
  describe '#rules' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }

    def policies(noteable = nil)
      return @policies if @policies

      noteable ||= issue
      note = create(:note, noteable: noteable, author: user, project: project)

      @policies = described_class.new(user, note)
    end

    context 'when the project is public' do
      context 'when the note author is not a project member' do
        it 'can edit a note' do
          expect(policies).to be_allowed(:update_note)
          expect(policies).to be_allowed(:admin_note)
          expect(policies).to be_allowed(:resolve_note)
          expect(policies).to be_allowed(:read_note)
        end
      end

      context 'when the noteable is a snippet' do
        it 'can edit note' do
          policies = policies(create(:project_snippet, project: project))

          expect(policies).to be_allowed(:update_note)
          expect(policies).to be_allowed(:admin_note)
          expect(policies).to be_allowed(:resolve_note)
          expect(policies).to be_allowed(:read_note)
        end
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
            expect(policies).to be_allowed(:update_note)
            expect(policies).to be_allowed(:admin_note)
            expect(policies).to be_allowed(:resolve_note)
            expect(policies).to be_allowed(:read_note)
          end
        end

        context 'when the note author is not a project member' do
          it 'can not edit a note' do
            expect(policies).to be_disallowed(:update_note)
            expect(policies).to be_disallowed(:admin_note)
            expect(policies).to be_disallowed(:resolve_note)
          end

          it 'can read a note' do
            expect(policies).to be_allowed(:read_note)
          end
        end
      end
    end
  end
end

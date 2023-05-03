# frozen_string_literal: true

RSpec.shared_examples 'note entity' do
  subject { entity.as_json }

  context 'basic note' do
    it 'exposes correct elements' do
      expect(subject).to include(
        :attachment,
        :author,
        :award_emoji,
        :base_discussion,
        :current_user,
        :discussion_id,
        :emoji_awardable,
        :note,
        :note_html,
        :noteable_note_url,
        :report_abuse_path,
        :resolvable,
        :type,
        :external_author
      )
    end

    it 'does not expose elements for specific notes cases' do
      expect(subject).not_to include(:last_edited_by, :last_edited_at, :system_note_icon_name)
    end

    it 'exposes author correctly' do
      expect(subject[:author]).to include(:id, :name, :username, :state, :avatar_url, :path)
    end

    it 'does not expose web_url for author' do
      expect(subject[:author]).not_to include(:web_url)
    end

    it 'exposes permission fields on current_user' do
      expect(subject[:current_user]).to include(:can_edit, :can_award_emoji, :can_resolve, :can_resolve_discussion)
    end

    it 'exposes the report_abuse_path' do
      expect(subject[:report_abuse_path]).to eq(add_category_abuse_reports_path)
    end

    describe ':can_resolve_discussion' do
      context 'discussion is resolvable' do
        before do
          expect(note.discussion).to receive(:resolvable?).and_return(true)
        end

        context 'user can resolve' do
          it 'is true' do
            expect(note.discussion).to receive(:can_resolve?).with(user).and_return(true)
            expect(subject[:current_user][:can_resolve_discussion]).to be_truthy
          end
        end

        context 'user cannot resolve' do
          it 'is false' do
            expect(note.discussion).to receive(:can_resolve?).with(user).and_return(false)
            expect(subject[:current_user][:can_resolve_discussion]).to be_falsey
          end
        end
      end

      context 'discussion is not resolvable' do
        it 'is false' do
          expect(note.discussion).to receive(:resolvable?).and_return(false)
          expect(subject[:current_user][:can_resolve_discussion]).to be_falsey
        end
      end
    end
  end

  describe ':outdated_line_change_path' do
    before do
      allow(note).to receive(:show_outdated_changes?).and_return(show_outdated_changes)
    end

    context 'when note shows outdated changes' do
      let(:show_outdated_changes) { true }

      it 'returns correct outdated_line_change_namespace_project_note_path' do
        path = "/#{note.project.namespace.path}/#{note.project.path}/notes/#{note.id}/outdated_line_change"
        expect(subject[:outdated_line_change_path]).to eq(path)
      end
    end

    context 'when note does not show outdated changes' do
      let(:show_outdated_changes) { false }

      it 'does not expose outdated_line_change_path' do
        expect(subject).not_to include(:outdated_line_change_path)
      end
    end
  end

  context 'when note was edited' do
    before do
      note.update!(updated_at: 1.minute.from_now, updated_by: user)
    end

    it 'exposes last_edited_at and last_edited_by elements' do
      expect(subject).to include(:last_edited_at, :last_edited_by)
    end
  end

  context 'when note is a system note' do
    before do
      note.update!(system: true)
    end

    it 'exposes system_note_icon_name element' do
      expect(subject).to include(:system_note_icon_name)
    end
  end
end

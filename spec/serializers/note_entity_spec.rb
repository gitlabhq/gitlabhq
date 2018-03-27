require 'spec_helper'

describe NoteEntity do
  include Gitlab::Routing

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }
  let(:note) { create(:note) }
  let(:user) { create(:user) }
  subject { entity.as_json }

  context 'basic note' do
    it 'exposes correct elements' do
      expect(subject).to include(:type, :author, :human_access, :note, :note_html, :current_user,
        :discussion_id, :emoji_awardable, :award_emoji, :toggle_award_path, :report_abuse_path, :path, :attachment)
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
  end

  context 'when note was edited' do
    before do
      note.update(updated_at: 1.minute.from_now, updated_by: user)
    end

    it 'exposes last_edited_at and last_edited_by elements' do
      expect(subject).to include(:last_edited_at, :last_edited_by)
    end
  end

  context 'when note is a system note' do
    before do
      note.update(system: true)
    end

    it 'exposes system_note_icon_name element' do
      expect(subject).to include(:system_note_icon_name)
    end
  end

  context 'when note is part of resolvable discussion' do
    before do
      allow(note).to receive(:part_of_discussion?).and_return(true)
      allow(note).to receive(:resolvable?).and_return(true)
    end

    it 'exposes paths to resolve note' do
      expect(subject).to include(:resolve_path, :resolve_with_issue_path)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotePresenter, feature_category: :team_planning do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:email) { 'user@example.com' }
  let_it_be(:note_text) { "added #{email}" }
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
  let_it_be_with_reload(:note) { create(:note, :system, author: Users::Internal.support_bot, note: note_text) }
  let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:obfuscated_email) { 'us*****@e*****.c**' }

  subject(:presenter) do
    described_class.new(note, current_user: user)
  end

  describe '#note' do
    subject { presenter.note }

    it_behaves_like 'a field with obfuscated email address'
  end

  describe '#note_html' do
    subject { presenter.note_html }

    it_behaves_like 'a field with obfuscated email address'

    it 'runs post processing pipeline' do
      # Ensure post process pipeline runs
      expect(Banzai).to receive(:render_field).with(note, :note, {}).and_call_original
      expect(Banzai).to receive(:post_process).and_call_original

      is_expected.to include(obfuscated_email)
    end
  end

  describe '#note_first_line_html' do
    subject { presenter.note_first_line_html }

    it_behaves_like 'a field with obfuscated email address'

    it 'runs post processing pipeline' do
      # Ensure post process pipeline runs
      expect(Banzai).to receive(:render_field).with(note, :note, {}).and_call_original
      expect(Banzai).to receive(:post_process).and_call_original

      is_expected.to include(obfuscated_email)
    end

    context 'when the note body is shorter than 125 characters' do
      before do
        note.note = 'note body content'
      end

      it 'returns the content unchanged' do
        is_expected.to eq('<p>note body content</p>')
      end
    end

    context 'when the note body is longer than 125 characters' do
      before do
        note.note = 'this is a note body content which is very, very, very, veeery, long and is supposed ' \
          'to be longer that 125 characters in length, with a few extra'
      end

      it 'returns the content trimmed with an ellipsis' do
        is_expected.to eq(
          '<p>this is a note body content which is very, very, very, veeery, long and is supposed ' \
            'to be longer that 125 characters in le...</p>')
      end
    end
  end

  describe '#external_author' do
    let!(:note_text) { "note body" }
    let!(:note) { build(:note, :system, author: Users::Internal.support_bot, note: note_text) }
    let!(:note_metadata) { build(:note_metadata, note: note) }

    subject { presenter.external_author }

    it_behaves_like 'a field with obfuscated email address'
  end
end

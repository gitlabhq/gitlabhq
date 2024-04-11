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
    # The RenderService calls Banzai::ObjectRenderer which
    # populates `redacted_note_html`. We also do this in
    # API controllers.
    prepared_notes = Notes::RenderService.new(user).execute([note])
    described_class.new(prepared_notes.first, current_user: user)
  end

  describe '#note' do
    subject { presenter.note }

    it_behaves_like 'a note content field with obfuscated email address'
  end

  describe '#note_html' do
    subject { presenter.note_html }

    it_behaves_like 'a note content field with obfuscated email address'

    context 'when redacted_note_html is not present' do
      subject(:presenter) do
        described_class.new(note, current_user: user).note_html
      end

      it 'falls back to note_html and obfuscates emails' do
        is_expected.to include(obfuscated_email)
      end
    end
  end
end

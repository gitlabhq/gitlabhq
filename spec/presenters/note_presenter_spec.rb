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

  describe '#external_author' do
    let!(:note_text) { "note body" }
    let!(:note) { build(:note, :system, author: Users::Internal.support_bot, note: note_text) }
    let!(:note_metadata) { build(:note_metadata, note: note) }

    subject { presenter.external_author }

    it_behaves_like 'a field with obfuscated email address'
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/snippets/_snippet.html.haml' do
  let_it_be(:snippet) { create(:project_snippet) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?) { true }

    @noteable_meta_data = Class.new { include Gitlab::NoteableMetadata }.new.noteable_meta_data([snippet], 'Snippet')
  end

  context 'snippet with statistics' do
    let_it_be(:snippet) { create(:project_snippet) }

    it 'renders correct file count and tooltip' do
      snippet.statistics.file_count = 3

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector("span.file_count", text: '3')
      expect(rendered).to have_selector("span.file_count[title=\"3 files\"]")
    end

    it 'renders correct file count and tooltip when file_count is 1' do
      snippet.statistics.file_count = 1

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector("span.file_count", text: '1')
      expect(rendered).to have_selector("span.file_count[title=\"1 file\"]")
    end

    it 'does not render file count when file count is 0' do
      snippet.statistics.file_count = 0

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('span.file_count')
    end
  end

  context 'snippet without statistics' do
    it 'does not render file count if statistics are not present' do
      snippet.statistics = nil

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('span.file_count')
    end
  end

  context 'spam icon and tooltip', feature_category: :insider_threat do
    context 'when the author of the snippet is not banned' do
      before do
        render 'shared/snippets/snippet', snippet: snippet
      end

      it 'does not render spam icon' do
        expect(rendered).not_to have_css('[data-testid="spam-icon"]')
      end

      it 'does not render tooltip' do
        expect(rendered).not_to have_selector("span.has-tooltip[title='This snippet is hidden because its author has been banned']")
      end
    end

    context 'when the author of the snippet is banned' do
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:snippet) { create(:project_snippet, author: banned_user) }

      before do
        render 'shared/snippets/snippet', snippet: snippet
      end

      it 'renders spam icon' do
        expect(rendered).to have_css('[data-testid="spam-icon"]')
      end

      it 'renders tooltip' do
        expect(rendered).to have_selector("span.has-tooltip[title='This snippet is hidden because its author has been banned']")
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/snippets/_snippet.html.haml' do
  let_it_be_with_reload(:snippet) { create(:project_snippet) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?) { true }

    @noteable_meta_data = Class.new { include Gitlab::NoteableMetadata }.new.noteable_meta_data([snippet], 'Snippet')
  end

  describe 'snippet title rendering', feature_category: :markdown do
    it 'renders the snippet title as a link using title_html' do
      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_link(snippet.title, href: gitlab_snippet_path(snippet))
    end

    context 'when title_html contains inline markup' do
      before do
        snippet.title = 'Hello `world`'
        snippet.save!
      end

      it 'renders the title with inline HTML markup' do
        render 'shared/snippets/snippet', snippet: snippet

        expect(rendered).to have_css('a.title code', text: 'world')
      end
    end

    context 'when title_html contains a reference link' do
      let_it_be(:issue) { create(:issue, project: snippet.project) }

      before do
        snippet.title = "Fixes #{issue.to_reference}"
        snippet.save!
      end

      it 'strips the inner reference link, leaving a single title link' do
        render 'shared/snippets/snippet', snippet: snippet

        expect(rendered).to have_link(snippet.title, href: gitlab_snippet_path(snippet))
        expect(rendered).not_to have_css('a.title a')
      end
    end
  end

  context 'for snippet with statistics' do
    let_it_be_with_reload(:snippet) { create(:project_snippet) }

    it 'renders correct file count and tooltip' do
      snippet.statistics.file_count = 3

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector(".file_count", text: '3')
      expect(rendered).to have_selector(".file_count[title=\"3 files\"]")
    end

    it 'renders correct file count and tooltip when file_count is 1' do
      snippet.statistics.file_count = 1

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector(".file_count", text: '1')
      expect(rendered).to have_selector(".file_count[title=\"1 file\"]")
    end

    it 'does not render file count when file count is 0' do
      snippet.statistics.file_count = 0

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('.file_count')
    end
  end

  context 'for snippet without statistics' do
    it 'does not render file count if statistics are not present' do
      snippet.statistics = nil

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('.file_count')
    end
  end

  context 'for snippet with spam icon and tooltip', feature_category: :insider_threat do
    context 'when the author of the snippet is not banned' do
      before do
        render 'shared/snippets/snippet', snippet: snippet
      end

      it 'does not render spam icon' do
        expect(rendered).not_to have_css('[data-testid="spam-icon"]')
      end

      it 'does not render tooltip' do
        expect(rendered).not_to have_selector(".has-tooltip[title='This snippet is hidden because its author has been banned']")
      end
    end

    context 'when the author of the snippet is banned' do
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be_with_reload(:snippet) { create(:project_snippet, author: banned_user) }

      before do
        render 'shared/snippets/snippet', snippet: snippet
      end

      it 'renders spam icon' do
        expect(rendered).to have_css('[data-testid="spam-icon"]')
      end

      it 'renders tooltip' do
        expect(rendered).to have_selector(".has-tooltip[title='This snippet is hidden because its author has been banned']")
      end
    end
  end
end

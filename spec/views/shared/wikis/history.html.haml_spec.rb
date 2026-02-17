# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/wikis/history.html.haml', feature_category: :wiki do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:wiki) { build_stubbed(:project_wiki, project: project) }
  let_it_be(:wiki_page) { build_stubbed(:wiki_page, container: project) }
  let(:commits_count) { 25 }

  before do
    assign(:wiki, wiki)
    assign(:page, wiki_page)
    assign(:commits_count, commits_count)
    assign(:commits, paginated_commits)

    allow(view).to receive(:paginate).and_return('')
  end

  def create_commits(range, page)
    commits = range.map do |i|
      build_stubbed(:commit, id: "commit#{i}", author_name: "Author #{i}", message: "Commit #{i}",
        authored_date: Time.parse('2024-01-01T00:00:00Z'))
    end
    Kaminari.paginate_array(commits, total_count: commits_count).page(page)
  end

  describe 'version numbering with pagination' do
    context 'when on first page' do
      let(:paginated_commits) { create_commits(1..20, 1) }

      it 'renders correct version numbers and version_number parameter in links' do
        render

        expect(rendered).to have_content('v25')
        expect(rendered).to have_content('v24')
        expect(rendered).to have_content('v6')
        expect(rendered).not_to have_content('v5')

        expect(rendered).to have_link(href: /version_number=25/)
        expect(rendered).to have_link(href: /version_number=6/)
      end
    end

    context 'when on second page' do
      let(:paginated_commits) { create_commits(1..20, 2) }

      it 'renders correct version numbers and version_number parameter in links' do
        render

        expect(rendered).to have_content('v5')
        expect(rendered).to have_content('v4')
        expect(rendered).to have_content('v1')
        expect(rendered).not_to have_content('v25')

        expect(rendered).to have_link(href: /version_number=5/)
        expect(rendered).to have_link(href: /version_number=1/)
      end
    end
  end

  describe 'table structure' do
    let(:paginated_commits) { create_commits(1..5, 1) }

    it 'renders all required columns' do
      render

      expect(rendered).to have_selector('th', text: 'Version')
      expect(rendered).to have_selector('th', text: 'Author')
      expect(rendered).to have_selector('th', text: 'Diff')
      expect(rendered).to have_selector('th', text: 'Last updated')
    end

    it 'renders all required rows' do
      render

      expect(rendered).to have_selector('td', text: 'v25')
      expect(rendered).to have_selector('td', text: 'Author 1')
      expect(rendered).to have_selector('td', text: 'Commit 1')
      expect(rendered).to have_selector('td', text: 'Jan 01, 2024')
    end
  end
end

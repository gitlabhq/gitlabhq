# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/show', feature_category: :global_search do
  let(:search_term) { nil }
  let(:user) { build(:user) }
  let(:search_service_presenter) do
    instance_double(SearchServicePresenter,
      without_count?: false,
      advanced_search_enabled?: false,
      zoekt_enabled?: false
    )
  end

  before do
    stub_template "search/_results.html.haml" => 'Results Partial'

    allow(view).to receive(:current_user) { user }

    assign(:search_service_presenter, search_service_presenter)
    assign(:search_term, search_term)
  end

  context 'when search term is supplied' do
    let(:search_term) { 'Search Foo' }

    it 'renders the results partial' do
      render

      expect(rendered).to render_template('search/_results')
    end
  end

  context 'when the search page is opened' do
    it 'does not render the results partial' do
      render

      expect(rendered).not_to render_template('search/_results')
    end

    it 'does render the sidebar' do
      render

      expect(rendered).to have_selector('#js-search-sidebar')
    end
  end

  context 'for unfurling support' do
    let(:group) { build(:group) }
    let(:search_results) do
      instance_double(Gitlab::GroupSearchResults).tap do |double|
        allow(double).to receive(:formatted_count).and_return(0)
      end
    end

    before do
      assign(:search_results, search_results)
      assign(:scope, 'issues')
      assign(:group, group)
    end

    context 'for search with full count' do
      let(:search_service_presenter) do
        instance_double(SearchServicePresenter,
          without_count?: false,
          advanced_search_enabled?: false,
          zoekt_enabled?: false
        )
      end

      it 'renders meta tags for a group' do
        render

        expect(view.page_description).to match(/\d+ issues for term '#{search_term}'/)
        expect(view.page_card_attributes).to eq("Namespace" => group.full_path)
      end

      it 'renders meta tags for both group and project' do
        project = build(:project, group: group)
        assign(:project, project)

        render

        expect(view.page_description).to match(/\d+ issues for term '#{search_term}'/)
        expect(view.page_card_attributes).to eq("Namespace" => group.full_path, "Project" => project.full_path)
      end
    end

    context 'for search without full count' do
      let(:search_service_presenter) do
        instance_double(SearchServicePresenter,
          without_count?: true,
          advanced_search_enabled?: false,
          zoekt_enabled?: false
        )
      end

      it 'renders meta tags for a group' do
        render

        expect(view.page_description).to match(/issues results for term '#{search_term}'/)
        expect(view.page_card_attributes).to eq("Namespace" => group.full_path)
      end

      it 'renders meta tags for both group and project' do
        project = build(:project, group: group)
        assign(:project, project)

        render

        expect(view.page_description).to match(/issues results for term '#{search_term}'/)
        expect(view.page_card_attributes).to eq("Namespace" => group.full_path, "Project" => project.full_path)
      end
    end
  end
end

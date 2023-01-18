# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/show', feature_category: :global_search do
  let(:search_term) { nil }
  let(:user) { build(:user) }
  let(:search_service_presenter) do
    instance_double(SearchServicePresenter, without_count?: false, advanced_search_enabled?: false)
  end

  before do
    stub_template "search/_category.html.haml" => 'Category Partial'
    stub_template "search/_results.html.haml" => 'Results Partial'

    assign(:search_service_presenter, search_service_presenter)
  end

  context 'search_page_vertical_nav feature flag enabled' do
    before do
      allow(view).to receive(:current_user) { user }
      assign(:search_term, search_term)
    end

    context 'when search term is supplied' do
      let(:search_term) { 'Search Foo' }

      it 'will not render category partial' do
        render

        expect(rendered).not_to render_template('search/_category')
        expect(rendered).to render_template('search/_results')
      end
    end
  end

  context 'search_page_vertical_nav feature flag disabled' do
    before do
      stub_feature_flags(search_page_vertical_nav: false)

      assign(:search_term, search_term)
    end

    context 'when the search page is opened' do
      it 'displays the title' do
        render

        expect(rendered).to have_selector('h1.page-title', text: 'Search')
        expect(rendered).not_to have_selector('h1.page-title code')
      end

      it 'does not render partials' do
        render

        expect(rendered).not_to render_template('search/_category')
        expect(rendered).not_to render_template('search/_results')
      end
    end

    context 'when search term is supplied' do
      let(:search_term) { 'Search Foo' }

      it 'renders partials' do
        render

        expect(rendered).to render_template('search/_category')
        expect(rendered).to render_template('search/_results')
      end

      context 'unfurling support' do
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

        context 'search with full count' do
          let(:search_service_presenter) do
            instance_double(SearchServicePresenter, without_count?: false, advanced_search_enabled?: false)
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

        context 'search without full count' do
          let(:search_service_presenter) do
            instance_double(SearchServicePresenter, without_count?: true, advanced_search_enabled?: false)
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
  end
end

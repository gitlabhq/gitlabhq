# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlFilteredSearchHelpers, feature_category: :tooling do
  let(:test_class) { Class.new { include GlFilteredSearchHelpers } }
  let(:helper) { test_class.new }
  let(:page) { instance_double(Capybara::Session) }
  let(:scope) { instance_double(Capybara::Node::Element) }
  let(:input_element) { instance_double(Capybara::Node::Element) }
  let(:dropdown_element) { instance_double(Capybara::Node::Element) }
  let(:suggestion_element) { instance_double(Capybara::Node::Element) }

  before do
    allow(helper).to receive(:page).and_return(page)
    allow(helper).to receive(:click_button)
    allow(helper).to receive(:wait_for_requests)
  end

  describe '#gl_filtered_search_input' do
    it 'finds input within filtered-search-input testid element' do
      expect(page).to receive(:find).with('[data-testid="filtered-search-input"] input').and_return(input_element)

      expect(helper.gl_filtered_search_input).to eq(input_element)
    end

    it 'accepts a custom scope' do
      expect(scope).to receive(:find).with('[data-testid="filtered-search-input"] input').and_return(input_element)

      expect(helper.gl_filtered_search_input(scope)).to eq(input_element)
    end
  end

  describe '#gl_filtered_search_dropdown' do
    it 'finds suggestion list element' do
      expect(page).to receive(:find).with('.gl-filtered-search-suggestion-list').and_return(dropdown_element)

      expect(helper.gl_filtered_search_dropdown).to eq(dropdown_element)
    end

    it 'accepts a custom scope' do
      expect(scope).to receive(:find).with('.gl-filtered-search-suggestion-list').and_return(dropdown_element)

      expect(helper.gl_filtered_search_dropdown(scope)).to eq(dropdown_element)
    end
  end

  describe '#gl_filtered_search_first_suggestion' do
    it 'finds first suggestion element within dropdown' do
      expect(page).to receive(:find).with('.gl-filtered-search-suggestion-list').and_return(dropdown_element)
      expect(dropdown_element).to receive(:first).with('.gl-filtered-search-suggestion').and_return(suggestion_element)

      expect(helper.gl_filtered_search_first_suggestion).to eq(suggestion_element)
    end

    it 'accepts a custom scope' do
      expect(scope).to receive(:find).with('.gl-filtered-search-suggestion-list').and_return(dropdown_element)
      expect(dropdown_element).to receive(:first).with('.gl-filtered-search-suggestion').and_return(suggestion_element)

      expect(helper.gl_filtered_search_first_suggestion(scope)).to eq(suggestion_element)
    end
  end

  describe '#gl_filtered_search_set_input' do
    before do
      allow(page).to receive(:find).with('[data-testid="filtered-search-input"] input').and_return(input_element)
      allow(input_element).to receive(:click)
      allow(input_element).to receive(:set)
    end

    it 'clicks and sets input value' do
      expect(input_element).to receive(:click)
      expect(input_element).to receive(:set).with('search term')

      helper.gl_filtered_search_set_input('search term')
    end

    it 'does not submit by default' do
      expect(helper).not_to receive(:click_button)
      expect(helper).not_to receive(:wait_for_requests)

      helper.gl_filtered_search_set_input('search term')
    end

    context 'when submit: true' do
      it 'clicks scoped Search button and waits for requests' do
        expect(input_element).to receive(:click)
        expect(input_element).to receive(:set).with('search term')
        expect(page).to receive(:click_button).with('Search')
        expect(helper).to receive(:wait_for_requests)

        helper.gl_filtered_search_set_input('search term', submit: true)
      end
    end

    context 'with custom scope' do
      it 'uses the provided scope to find input' do
        expect(scope).to receive(:find).with('[data-testid="filtered-search-input"] input').and_return(input_element)
        expect(input_element).to receive(:click)
        expect(input_element).to receive(:set).with('scoped search')

        helper.gl_filtered_search_set_input('scoped search', scope: scope)
      end
    end
  end
end

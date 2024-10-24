# frozen_string_literal: true

module FilteredSearchHelpers
  def filtered_search
    page.find('.filtered-search')
  end

  # Enables input to be set (similar to copy and paste)
  def input_filtered_search(search_term, submit: true, extra_space: true)
    search = search_term
    if extra_space
      # Add an extra space to engage visual tokens
      search = "#{search_term} "
    end

    filtered_search.set(search, rapid: false)

    if submit
      # Wait for the lazy author/assignee tokens that
      # swap out the username with an avatar and name
      wait_for_requests
      filtered_search.send_keys(:enter)
    end
  end

  # Select a label clicking in the search dropdown instead
  # of entering label names on the input.
  def select_label_on_dropdown(label_title)
    input_filtered_search("label:=", submit: false)

    within('#js-dropdown-label') do
      wait_for_requests

      find('li', text: label_title).click
    end

    filtered_search.send_keys(:enter)
  end

  def expect_filtered_search_dropdown_results(filter_dropdown, count)
    expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: count)
  end

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)

    expect(page).to have_selector('.issue', count: open_count)
  end

  # Enables input to be added character by character
  def input_filtered_search_keys(search_term)
    # Add an extra space to engage visual tokens
    filtered_search.send_keys("#{search_term} ")
    filtered_search.send_keys(:enter)
  end

  def expect_filtered_search_input(input)
    expect(find('.filtered-search').value).to eq(input)
  end

  def clear_search_field
    find('.filtered-search-box .clear-search').click
  end

  def reset_filters
    clear_search_field
    filtered_search.send_keys(:enter)
  end

  def expect_filtered_search_input_empty
    expect(find('.filtered-search, [data-testid="filtered-search-term-input"]').value).to eq('')
  end

  # Iterates through each visual token inside
  # .tokens-container to make sure the correct names and values are rendered
  def expect_tokens(tokens)
    page.within '.filtered-search-box .tokens-container' do
      token_elements = page.all(:css, 'li.filtered-search-token')

      tokens.each_with_index do |token, index|
        el = token_elements[index]

        expect(el.find('.name')).to have_content(token[:name])
        expect(el.find('.operator')).to have_content(token[:operator]) if token[:operator].present?
        expect(el.find('.value')).to have_content(token[:value]) if token[:value].present?

        # gl-emoji content is blank when the emoji unicode is not supported
        if token[:emoji_name].present?
          selector = %(gl-emoji[data-name="#{token[:emoji_name]}"])
          expect(el.find('.value')).to have_css(selector)
        end
      end
    end
  end

  # Same as `expect_tokens` but works with GlFilteredSearch
  def expect_vue_tokens(tokens)
    page.within '.gl-search-box-by-click .gl-filtered-search-scrollable' do
      token_elements = page.all(:css, '.gl-filtered-search-token')

      tokens.each_with_index do |token, index|
        el = token_elements[index]

        expect(el.find('.gl-filtered-search-token-type')).to have_content(token[:name])
        expect(el.find('.gl-filtered-search-token-operator')).to have_content(token[:operator]) if token[:operator].present?
        expect(el.find('.gl-filtered-search-token-data')).to have_content(token[:value]) if token[:value].present?

        # gl-emoji content is blank when the emoji unicode is not supported
        if token[:emoji_name].present?
          selector = %(gl-emoji[data-name="#{token[:emoji_name]}"])
          expect(el.find('.gl-filtered-search-token-data-content')).to have_css(selector)
        end
      end
    end
  end

  def create_token(token_name, token_value = nil, symbol = nil, token_operator = '=')
    { name: token_name, operator: token_operator, value: "#{symbol}#{token_value}" }
  end

  def author_token(author_name = nil)
    create_token('Author', author_name)
  end

  def assignee_token(assignee_name = nil)
    create_token('Assignee', assignee_name)
  end

  def reviewer_token(reviewer_name = nil)
    create_token('Reviewer', reviewer_name)
  end

  def milestone_token(milestone_name = nil, has_symbol = true, operator = '=')
    symbol = has_symbol ? '%' : nil
    create_token('Milestone', milestone_name, symbol, operator)
  end

  def release_token(release_tag = nil)
    create_token('Release', release_tag)
  end

  def label_token(label_name = nil, has_symbol = false)
    symbol = has_symbol ? '~' : nil
    create_token('Label', label_name, symbol)
  end

  def reaction_token(reaction_name = nil, is_emoji = true)
    if is_emoji
      { name: 'My-Reaction', emoji_name: reaction_name }
    else
      create_token('My-Reaction', reaction_name)
    end
  end

  def default_placeholder
    'Search or filter results…'
  end

  def get_filtered_search_placeholder
    find('.filtered-search')['placeholder']
  end

  def remove_recent_searches
    execute_script('window.localStorage.clear();')
  end

  def set_recent_searches(key, input)
    execute_script("window.localStorage.setItem('#{key}', '#{input}');")
  end

  def wait_for_filtered_search(text)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until find('.filtered-search').value.strip == text
    end
  end

  def close_dropdown_menu_if_visible
    find('.dropdown-menu-toggle', visible: :all).tap do |toggle|
      toggle.click if toggle.visible?
    end
  end

  ##
  # For use with gl-filtered-search
  def select_tokens(*args, submit: false, search_token: false, input_text: 'Search')
    within '[data-testid="filtered-search-input"]' do
      find_field(input_text).click

      args.each do |token|
        # Move mouse away to prevent invoking tooltips on usernames, which blocks the search input
        find_button('Search').hover

        if search_token
          find_by_testid('filtered-search-token-segment-input').send_keys token.to_s
        end

        click_on token.to_s, match: :first

        wait_for_requests
      end
    end

    if submit
      send_keys :enter
    end
  end

  def get_suggestion_count
    all('.gl-filtered-search-suggestion').size
  end

  def submit_search_term(value)
    click_filtered_search_bar
    send_keys(value, :enter, :enter)
  end

  def click_filtered_search_bar
    find('.gl-filtered-search-last-item').click
  end

  def click_token_segment(value)
    find('.gl-filtered-search-token-segment', text: value).click
  end

  def toggle_sort_direction
    page.within('.vue-filtered-search-bar-container .sort-dropdown-container') do
      page.find("button[title^='Sort direction']").click
      wait_for_requests
    end
  end

  def change_sort_by(value)
    within_element '.sort-dropdown-container' do
      find_by_testid('base-dropdown-toggle').click
      find('li', text: value).click
      wait_for_requests
    end
  end

  def expect_visible_suggestions_list
    expect(page).to have_css('.gl-filtered-search-suggestion-list')
  end

  def expect_hidden_suggestions_list
    expect(page).not_to have_css('.gl-filtered-search-suggestion-list')
  end

  def expect_suggestion(value)
    expect(page).to have_css('.gl-filtered-search-suggestion', text: value)
  end

  def expect_no_suggestion(value)
    expect(page).not_to have_css('.gl-filtered-search-suggestion', text: value)
  end

  def expect_suggestion_count(count)
    expect(page).to have_css('.gl-filtered-search-suggestion', count: count)
  end

  def expect_assignee_token(value)
    expect(page).to have_css '.gl-filtered-search-token, .js-visual-token', text: /Assignee (=|is) #{Regexp.escape(value)}/
  end

  def expect_unioned_assignee_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Assignee is one of #{Regexp.escape(value)}/
  end

  def expect_author_token(value)
    expect(page).to have_css '.gl-filtered-search-token, .js-visual-token', text: /Author (=|is) #{Regexp.escape(value)}/
  end

  def expect_label_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Label (=|is) #{Regexp.escape(value)}/
  end

  def expect_negated_label_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Label (!=|is not one of) #{Regexp.escape(value)}/
  end

  def expect_milestone_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Milestone (=|is) %#{Regexp.escape(value)}/
  end

  def expect_negated_milestone_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Milestone (!=|is not) %#{Regexp.escape(value)}/
  end

  def expect_epic_token(value)
    expect(page).to have_css '.gl-filtered-search-token', text: /Epic (=|is) #{value}/
  end

  def expect_search_term(value)
    value.split(' ').each do |term|
      expect(page).to have_css '.gl-filtered-search-term', text: term
    end
  end

  def expect_empty_search_term
    expect(page).to have_css '.gl-filtered-search-term', text: ''
  end

  def expect_token_segment(value)
    expect(page).to have_css '.gl-filtered-search-token-segment', text: value
  end

  def expect_recent_searches_history_item(value)
    expect(page).to have_css '.gl-search-box-by-click-history-item', text: value
  end

  def expect_recent_searches_history_item_count(count)
    expect(page).to have_css '.gl-search-box-by-click-history-item', count: count
  end
end

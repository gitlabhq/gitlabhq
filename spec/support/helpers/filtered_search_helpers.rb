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

    filtered_search.set(search)

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
    input_filtered_search("label:", submit: false)

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
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
    end
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

  def init_label_search
    filtered_search.set('label:')
    # This ensures the dropdown is shown
    expect(find('#js-dropdown-label')).not_to have_css('.filter-dropdown-loading')
  end

  def expect_filtered_search_input_empty
    expect(find('.filtered-search').value).to eq('')
  end

  # Iterates through each visual token inside
  # .tokens-container to make sure the correct names and values are rendered
  def expect_tokens(tokens)
    page.within '.filtered-search-box .tokens-container' do
      token_elements = page.all(:css, 'li.filtered-search-token')

      tokens.each_with_index do |token, index|
        el = token_elements[index]

        expect(el.find('.name')).to have_content(token[:name])
        expect(el.find('.value')).to have_content(token[:value]) if token[:value].present?

        # gl-emoji content is blank when the emoji unicode is not supported
        if token[:emoji_name].present?
          selector = %(gl-emoji[data-name="#{token[:emoji_name]}"])
          expect(el.find('.value')).to have_css(selector)
        end
      end
    end
  end

  def create_token(token_name, token_value = nil, symbol = nil)
    { name: token_name, value: "#{symbol}#{token_value}" }
  end

  def author_token(author_name = nil)
    create_token('Author', author_name)
  end

  def assignee_token(assignee_name = nil)
    create_token('Assignee', assignee_name)
  end

  def milestone_token(milestone_name = nil, has_symbol = true)
    symbol = has_symbol ? '%' : nil
    create_token('Milestone', milestone_name, symbol)
  end

  def release_token(release_tag = nil)
    create_token('Release', release_tag)
  end

  def label_token(label_name = nil, has_symbol = true)
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
    'Search or filter results...'
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
end

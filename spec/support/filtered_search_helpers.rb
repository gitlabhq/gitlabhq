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
    page.find '.filtered-search-box .tokens-container' do
      page.all(:css, '.tokens-container li.js-visual-token').each_with_index do |el, index|
        token_name = tokens[index][:name]
        token_value = tokens[index][:value]

        expect(el.find('.name')).to have_content(token_name)
        if token_value
          value_container = el.find('.value-container')

          # There is a race condition here for the Author dropdown where it first fills the value with
          # the user and then changes to display the Name. We don't have to wait, just need to handle both "states"
          if value_container['data-original-value']
            # container finished loading, so we can get value from data attribute

            expect(value_container['data-original-value']).to eq(token_value)
          else
            # container still loading, we can get value from the node's content
            expect(el.find('.value')).to have_content(token_value)
          end
        end
      end
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
end

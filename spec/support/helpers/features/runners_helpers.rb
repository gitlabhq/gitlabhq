# frozen_string_literal: true

module Features
  module RunnersHelpers
    def within_runner_row(runner_id)
      within "[data-testid='runner-row-#{runner_id}']" do
        yield
      end
    end

    def search_bar_selector
      '[data-testid="runners-filtered-search"]'
    end

    # The filters must be clicked first to be able to receive events
    # See: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1493
    def focus_filtered_search
      page.within(search_bar_selector) do
        page.find('.gl-filtered-search-term-token').click
      end
    end

    def input_filtered_search_keys(search_term)
      focus_filtered_search

      page.within(search_bar_selector) do
        page.find('input').send_keys(search_term)
        click_on 'Search'
      end

      wait_for_requests
    end

    def open_filtered_search_suggestions(filter)
      focus_filtered_search

      page.within(search_bar_selector) do
        click_on filter
      end

      wait_for_requests
    end

    def input_filtered_search_filter_is_only(filter, value)
      focus_filtered_search

      page.within(search_bar_selector) do
        click_on filter

        # For OPERATORS_IS, clicking the filter
        # immediately preselects "=" operator

        page.find('input').send_keys(value)
        page.find('input').send_keys(:enter)

        click_on 'Search'
      end

      wait_for_requests
    end
  end
end

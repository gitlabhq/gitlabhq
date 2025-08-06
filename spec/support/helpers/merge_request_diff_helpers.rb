# frozen_string_literal: true

module MergeRequestDiffHelpers
  PageEndReached = Class.new(StandardError)

  def add_diff_line_draft_comment(comment, line_holder, diff_side = nil)
    click_diff_line(line_holder, diff_side)
    page.within('.js-discussion-note-form') do
      fill_in('note_note', with: comment)
      begin
        click_button('Start a review', wait: 0.1)
      rescue Capybara::ElementNotFound
        click_button('Add to review')
      end
    end
  end

  def click_diff_line(line_holder, diff_side = nil)
    line = get_line_components(line_holder, diff_side)
    scroll_to_elements_bottom(line_holder)
    line_holder.hover
    line[:num].find('.js-add-diff-note-button').click
  end

  def get_line_components(line_holder, diff_side = nil)
    if diff_side.nil?
      get_inline_line_components(line_holder)
    else
      get_parallel_line_components(line_holder, diff_side)
    end
  end

  def get_inline_line_components(line_holder)
    { content: line_holder.find('.line_content', match: :first), num: line_holder.find('.diff-line-num', match: :first) }
  end

  def get_parallel_line_components(line_holder, diff_side = nil)
    side_index = diff_side == 'left' ? 0 : 1
    # Wait for `.line_content`
    line_holder.find('.line_content', match: :first)
    # Wait for `.diff-line-num`
    line_holder.find('.diff-line-num', match: :first)
    { content: line_holder.all('.line_content')[side_index], num: line_holder.all('.diff-line-num')[side_index] }
  end

  def has_reached_page_end
    evaluate_script("(window.innerHeight + window.scrollY) >= document.body.offsetHeight")
  end

  def scroll_to_elements_bottom(element)
    evaluate_script("(function(el) {
      window.scrollBy(0, el.getBoundingClientRect().bottom - window.innerHeight);
    })(arguments[0]);", element.native)
  end

  # we're not using Capybara's .obscured here because it also checks if the element is clickable
  def within_viewport?(element)
    evaluate_script("(function(el) {
      var rect = el.getBoundingClientRect();
      return (
        rect.bottom >= 0 &&
        rect.right >= 0 &&
        rect.top <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.left <= (window.innerWidth || document.documentElement.clientWidth)
      );
    })(arguments[0]);", element.native)
  end

  def find_within_viewport(selector, **options)
    begin
      element = find(selector, **options, wait: 2)
    rescue Capybara::ElementNotFound
      return
    end
    return element if within_viewport?(element)

    nil
  end

  def find_by_scrolling(selector, **options)
    element = find_within_viewport(selector, **options)
    return element if element

    page.execute_script "window.scrollTo(0,0)"
    until element

      if has_reached_page_end
        raise PageEndReached, "Failed to find any elements matching a selector '#{selector}' by scrolling. Page end reached."
      end

      page.execute_script "window.scrollBy(0,window.innerHeight/1.5)"
      element = find_within_viewport(selector, **options)
    end
    element
  end
end

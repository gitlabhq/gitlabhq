# frozen_string_literal: true

module MergeRequestHelpers
  def visit_merge_requests(project, opts = {})
    visit project_merge_requests_path project, opts
  end

  def first_merge_request
    page.all('ul.issuable-list > li').first.text
  end

  def last_merge_request
    page.all('ul.issuable-list > li').last.text
  end

  def expect_mr_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issuable-list' do
      expect(page).to have_selector('.merge-request', count: open_count)
    end
  end
end

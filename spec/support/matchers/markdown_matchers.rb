# MarkdownMatchers
#
# Custom matchers for our custom HTML::Pipeline filters. These are used to test
# that specific filters are or are not used by our defined pipelines.
#
# Must be included manually.
module MarkdownMatchers
  extend RSpec::Matchers::DSL
  include Capybara::Node::Matchers

  # RelativeLinkFilter
  matcher :parse_relative_links do
    set_default_markdown_messages

    match do |actual|
      link  = actual.at_css('a:contains("Relative Link")')
      image = actual.at_css('img[alt="Relative Image"]')

      expect(link['href']).to end_with('master/doc/README.md')
      expect(image['src']).to end_with('master/app/assets/images/touch-icon-ipad.png')
    end
  end

  # EmojiFilter
  matcher :parse_emoji do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('img.emoji', count: 10)
    end
  end

  # TableOfContentsFilter
  matcher :create_header_links do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('h1 a#gitlab-markdown')
      expect(actual).to have_selector('h2 a#markdown')
      expect(actual).to have_selector('h3 a#autolinkfilter')
    end
  end

  # AutolinkFilter
  matcher :create_autolinks do
    def have_autolink(link)
      have_link(link, href: link)
    end

    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_autolink('http://about.gitlab.com/')
      expect(actual).to have_autolink('https://google.com/')
      expect(actual).to have_autolink('ftp://ftp.us.debian.org/debian/')
      expect(actual).to have_autolink('smb://foo/bar/baz')
      expect(actual).to have_autolink('irc://irc.freenode.net/git')
      expect(actual).to have_autolink('http://localhost:3000')

      %w(code a kbd).each do |elem|
        expect(body).not_to have_selector("#{elem} a")
      end
    end
  end

  # UserReferenceFilter
  matcher :reference_users do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-project_member', count: 3)
    end
  end

  # IssueReferenceFilter
  matcher :reference_issues do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-issue', count: 3)
    end
  end

  # MergeRequestReferenceFilter
  matcher :reference_merge_requests do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-merge_request', count: 3)
      expect(actual).to have_selector('em a.gfm-merge_request')
    end
  end

  # SnippetReferenceFilter
  matcher :reference_snippets do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-snippet', count: 2)
    end
  end

  # CommitRangeReferenceFilter
  matcher :reference_commit_ranges do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-commit_range', count: 2)
    end
  end

  # CommitReferenceFilter
  matcher :reference_commits do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-commit', count: 2)
    end
  end

  # LabelReferenceFilter
  matcher :reference_labels do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-label', count: 3)
    end
  end

  # TaskListFilter
  matcher :parse_task_lists do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('ul.task-list', count: 2)
      expect(actual).to have_selector('li.task-list-item', count: 7)
      expect(actual).to have_selector('input[checked]', count: 3)
    end
  end
end

# Monkeypatch the matcher DSL so that we can reduce some noisy duplication for
# setting the failure messages for these matchers
module RSpec::Matchers::DSL::Macros
  def set_default_markdown_messages
    failure_message do
      # expected to parse emoji, but didn't
      "expected to #{description}, but didn't"
    end

    failure_message_when_negated do
      # expected not to parse task lists, but did
      "expected not to #{description}, but did"
    end
  end
end

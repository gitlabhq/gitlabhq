# frozen_string_literal: true

# MarkdownMatchers
#
# Custom matchers for our custom HTML::Pipeline filters. These are used to test
# that specific filters are or are not used by our defined pipelines.
#
# Must be included manually.
module MarkdownMatchers
  extend RSpec::Matchers::DSL
  include Capybara::Node::Matchers

  # UploadLinkFilter
  matcher :parse_upload_links do
    set_default_markdown_messages

    match do |actual|
      link = actual.at_css('a:contains("Relative Upload Link")')
      image = actual.at_css('img[alt="Relative Upload Image"]')

      expect(link['href']).to eq("/#{project.full_path}/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg")
      expect(image['data-src']).to eq("/#{project.full_path}/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg")
    end
  end

  # RepositoryLinkFilter
  matcher :parse_repository_links do
    set_default_markdown_messages

    match do |actual|
      link = actual.at_css('a:contains("Relative Link")')
      image = actual.at_css('img[alt="Relative Image"]')

      expect(link['href']).to end_with('master/doc/README.md')
      expect(image['data-src']).to end_with('master/app/assets/images/touch-icon-ipad.png')
    end
  end

  # EmojiFilter
  matcher :parse_emoji do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('gl-emoji', count: 10)

      emoji_element = actual.at_css('gl-emoji')
      expect(emoji_element['data-name'].to_s).not_to be_empty
      expect(emoji_element['data-unicode-version'].to_s).not_to be_empty
    end
  end

  # TableOfContentsFilter
  matcher :create_header_links do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('h1 a#user-content-gitlab-markdown')
      expect(actual).to have_selector('h2 a#user-content-markdown')
      expect(actual).to have_selector('h3 a#user-content-autolinkfilter')
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

  # GollumTagsFilter
  matcher :parse_gollum_tags do
    def have_image(src)
      have_css("img[data-src$='#{src}']")
    end

    prefix = '/namespace1/gitlabhq/wikis'
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_link('linked-resource', href: "#{prefix}/linked-resource")
      expect(actual).to have_link('link-text', href: "#{prefix}/linked-resource")
      expect(actual).to have_link('http://example.com', href: 'http://example.com')
      expect(actual).to have_link('link-text', href: 'http://example.com/pdfs/gollum.pdf')
      expect(actual).to have_image("#{prefix}/images/example.jpg")
      expect(actual).to have_image('http://example.com/images/example.jpg')
    end
  end

  # UserReferenceFilter
  matcher :reference_users do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-project_member', count: 4)
    end
  end

  # IssueReferenceFilter
  matcher :reference_issues do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-issue', count: 6)
    end
  end

  # MergeRequestReferenceFilter
  matcher :reference_merge_requests do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-merge_request', count: 6)
      expect(actual).to have_selector('em a.gfm-merge_request')
    end
  end

  # SnippetReferenceFilter
  matcher :reference_snippets do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-snippet', count: 5)
    end
  end

  # CommitRangeReferenceFilter
  matcher :reference_commit_ranges do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-commit_range', count: 5)
    end
  end

  # CommitReferenceFilter
  matcher :reference_commits do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-commit', count: 5)
    end
  end

  # LabelReferenceFilter
  matcher :reference_labels do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-label', count: 4)
    end
  end

  # MilestoneReferenceFilter
  matcher :reference_milestones do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-milestone', count: 8)
    end
  end

  # AlertReferenceFilter
  matcher :reference_alerts do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('a.gfm.gfm-alert', count: 5)
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

  # InlineDiffFilter
  matcher :parse_inline_diffs do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('span.idiff.addition', count: 2)
      expect(actual).to have_selector('span.idiff.deletion', count: 2)
    end
  end

  # VideoLinkFilter
  matcher :parse_video_links do
    set_default_markdown_messages

    match do |actual|
      video = actual.at_css('video')

      expect(video['src']).to end_with('/assets/videos/gitlab-demo.mp4')
    end
  end

  # AudioLinkFilter
  matcher :parse_audio_links do
    set_default_markdown_messages

    match do |actual|
      audio = actual.at_css('audio')

      expect(audio['src']).to end_with('/assets/audio/gitlab-demo.wav')
    end
  end

  # ColorFilter
  matcher :parse_colors do
    set_default_markdown_messages

    match do |actual|
      color_chips = actual.css('code > span.gfm-color_chip > span')

      expect(color_chips.count).to eq(9)

      [
        '#F00', '#F00A', '#FF0000', '#FF0000AA', 'RGB(0,255,0)',
        'RGB(0%,100%,0%)', 'RGBA(0,255,0,0.7)', 'HSL(540,70%,50%)',
        'HSLA(540,70%,50%,0.7)'
      ].each_with_index do |color, i|
        parsed_color = Banzai::ColorParser.parse(color)
        expect(color_chips[i]['style']).to match("background-color: #{parsed_color};")
        expect(color_chips[i].parent.parent.content).to match(color)
      end
    end
  end

  # MermaidFilter
  matcher :parse_mermaid do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_selector('code.js-render-mermaid')
    end
  end

  # PLantumlFilter
  matcher :parse_plantuml do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_link(href: 'http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd9vm80EtS5lW00')
    end
  end

  # KrokiFilter
  matcher :parse_kroki do
    set_default_markdown_messages

    match do |actual|
      expect(actual).to have_link(href: 'http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==')
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

MarkdownMatchers.prepend_mod_with('MarkdownMatchers')

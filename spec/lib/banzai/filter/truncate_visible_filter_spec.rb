# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TruncateVisibleFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:project) { build(:project, :repository) }
  let_it_be(:max_chars) { 100 }
  let_it_be(:user) do
    user = create(:user, username: 'gfm')
    project.add_maintainer(user)
    user
  end

  # Since we're truncating nodes of an html document, actually use the
  # full pipeline to generate full documents.
  def convert_markdown(text, context = {})
    Banzai::Pipeline::FullPipeline.to_html(text, { project: project, no_sourcepos: true }.merge(context))
  end

  shared_examples_for 'truncates text' do
    specify do
      html = convert_markdown(markdown)
      doc = filter(html, { truncate_visible_max_chars: max_chars })

      expect(doc.to_html).to match(expected)
    end
  end

  describe 'displays inline code' do
    let(:markdown) { 'Text with `inline code`' }
    let(:expected) { 'Text with <code>inline code</code>' }

    it_behaves_like 'truncates text'
  end

  describe 'truncates the text with multiple paragraphs' do
    let(:markdown) { "Paragraph 1\n\nParagraph 2" }
    let(:expected) { 'Paragraph 1...' }

    it_behaves_like 'truncates text'
  end

  describe 'truncates the first line of a code block' do
    let(:markdown) { "```\nCode block\nwith two lines\n```" }
    let(:expected) { "Code block...</span></code>" }

    it_behaves_like 'truncates text'
  end

  describe 'preserves code color scheme' do
    let(:max_chars) { 150 }
    let(:markdown) { "```ruby\ndef test\n  'hello world'\nend\n```" }
    let(:expected) do
      '<code><span id="LC1" class="line" lang="ruby">' \
      '<span class="k">def</span> <span class="nf">test</span>...</span>'
    end

    it_behaves_like 'truncates text'
  end

  describe 'truncates a single long line of text' do
    let(:max_chars) { 150 }
    let(:text) { 'The quick brown fox jumped over the lazy dog twice' } # 50 chars
    let(:markdown) { text * 4 }
    let(:expected) { (text * 2).sub(/.{3}/, '...') }

    it_behaves_like 'truncates text'
  end

  it 'preserves a link href when link text is truncated' do
    max_chars = 150
    text = 'The quick brown fox jumped over the lazy dog' # 44 chars
    link_url = 'http://example.com/foo/bar/baz' # 30 chars
    markdown = "#{text}#{text}#{text} #{link_url}" # 163 chars
    expected_link_text = 'http://example...</a>'

    html = convert_markdown(markdown)
    doc = filter(html, { truncate_visible_max_chars: max_chars })

    expect(doc.to_html).to match(link_url)
    expect(doc.to_html).to match(expected_link_text)
  end

  it 'truncates HTML properly' do
    markdown = "@#{user.username}, can you look at this?\nHello world\n"

    html = convert_markdown(markdown)
    doc = filter(html, { truncate_visible_max_chars: max_chars })

    # Make sure we didn't create invalid markup
    expect(doc.errors).to be_empty

    # Leading user link
    expect(doc.css('a').length).to eq(1)
    expect(doc.css('a')[0].attr('href')).to eq urls.user_path(user)
    expect(doc.css('a')[0].text).to eq "@#{user.username}"
    expect(doc.content).to eq "@#{user.username}, can you look at this?..."
  end

  it 'truncates HTML with emoji properly' do
    markdown = "foo :wink:\nbar :grinning:"
    # actual = first_line_in_markdown(object, attribute, 100, project: project)

    html = convert_markdown(markdown)
    doc = filter(html, { truncate_visible_max_chars: max_chars })

    # Make sure we didn't create invalid markup
    # But also account for the 2 errors caused by the unknown `gl-emoji` elements
    expect(doc.errors.length).to eq(2)

    expect(doc.css('gl-emoji').length).to eq(2)
    expect(doc.css('gl-emoji')[0].attr('data-name')).to eq 'wink'
    expect(doc.css('gl-emoji')[1].attr('data-name')).to eq 'grinning'

    expect(doc.content).to eq "foo 😉\nbar 😀"
  end

  it 'does not truncate if truncate_visible_max_chars not specified' do
    markdown = "@#{user.username}, can you look at this?\nHello world"

    html = convert_markdown(markdown)
    doc = filter(html)

    expect(doc.content).to eq markdown
  end
end

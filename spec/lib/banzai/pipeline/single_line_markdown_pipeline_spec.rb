# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::SingleLineMarkdownPipeline, feature_category: :markdown do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  it_behaves_like 'sanitize pipeline'

  it 'processes markdown and does not surround output with a paragraph tag' do
    text = '_italic_ and `code`'

    expect(to_html(text)).to eq('<em>italic</em> and <code>code</code>')
  end

  it 'removes additional block level tags pre, p, img, ol, ul, and li' do
    text = <<~MARKDOWN
      Hello world! ![](world.png)

      - item one
      - item two

      1. number one
      2. number two

      ```ruby
      x = 1
      ```
    MARKDOWN

    expected = "Hello world!  \n \n item one \n item two \n \n \n number one \n number two \n \n <code>x = 1\n</code>"

    expect(to_html(text)).to eq(expected)
  end

  it 'handles emojis and autolinking' do
    text = ':smile: using http://example.com'
    result = to_html(text)

    expect(result).to include('gl-emoji')
    expect(result).to include('<a href="http://example.com"')
  end

  it 'recognizes references' do
    text = "Issue #{issue.to_reference}, User #{user.to_reference}"
    result = to_html(text)

    expect(result).to include('data-reference-type="issue"')
    expect(result).to include('data-reference-type="user"')
  end

  it 'does not recognize references in inline code' do
    text = "Issue `#{issue.to_reference}`, User `#{user.to_reference}`"
    result = to_html(text)

    expect(result).not_to include('data-reference-type="issue"')
    expect(result).not_to include('data-reference-type="user"')
  end

  def to_html(text)
    described_class.to_html(text, project: project, pipeline: :single_line_markdown)
  end
end

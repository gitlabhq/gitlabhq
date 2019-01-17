require 'rails_helper'

describe Banzai::Pipeline::FullPipeline do
  describe 'References' do
    let(:project) { create(:project, :public) }
    let(:issue)   { create(:issue, project: project) }

    it 'handles markdown inside a reference' do
      markdown = "[some `code` inside](#{issue.to_reference})"
      result = described_class.call(markdown, project: project)
      link_content = result[:output].css('a').inner_html
      expect(link_content).to eq('some <code>code</code> inside')
    end

    it 'sanitizes reference HTML' do
      link_label = '<script>bad things</script>'
      markdown = "[#{link_label}](#{issue.to_reference})"
      result = described_class.to_html(markdown, project: project)
      expect(result).not_to include(link_label)
    end

    it 'escapes the data-original attribute on a reference' do
      markdown = %Q{[">bad things](#{issue.to_reference})}
      result = described_class.to_html(markdown, project: project)
      expect(result).to include(%{data-original='\"&gt;bad things'})
    end
  end

  describe 'footnotes' do
    let(:project)    { create(:project, :public) }
    let(:html)       { described_class.to_html(footnote_markdown, project: project) }
    let(:identifier) { html[/.*fnref1-(\d+).*/, 1] }
    let(:footnote_markdown) do
      <<~EOF
        first[^1] and second[^second]
        [^1]: one
        [^second]: two
      EOF
    end

    let(:filtered_footnote) do
      <<~EOF
        <p dir="auto">first<sup class="footnote-ref"><a href="#fn1-#{identifier}" id="fnref1-#{identifier}">1</a></sup> and second<sup class="footnote-ref"><a href="#fn2-#{identifier}" id="fnref2-#{identifier}">2</a></sup></p>

        <section class="footnotes"><ol>
        <li id="fn1-#{identifier}">
        <p>one <a href="#fnref1-#{identifier}" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        <li id="fn2-#{identifier}">
        <p>two <a href="#fnref2-#{identifier}" class="footnote-backref"><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
        </ol></section>
      EOF
    end

    it 'properly adds the necessary ids and classes' do
      expect(html.lines.map(&:strip).join("\n")).to eq filtered_footnote
    end
  end
end

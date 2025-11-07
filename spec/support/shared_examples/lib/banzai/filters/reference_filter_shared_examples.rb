# frozen_string_literal: true

# Specs for reference links containing HTML.
#
# Requires a reference:
#   let(:reference) { '#42' }
RSpec.shared_examples 'a reference containing an element node' do
  let(:inner_html) { 'element <code>node</code> inside' }
  let(:reference_with_element) { %(<a href="#{reference}">#{inner_html}</a>) }

  it 'does not escape inner html' do
    doc = reference_filter(reference_with_element, try(:context) || {})

    expect(doc.children.first.children.first.inner_html).to eq(inner_html)
  end
end

# Requires a reference, subject and subject_name:
#   subject { create(:user) }
#   let(:reference) { subject.to_reference }
#   let(:subject_name) { 'user' }
RSpec.shared_examples 'user reference or project reference' do
  shared_examples 'it contains a data- attribute' do
    it 'includes a data- attribute' do
      doc = reference_filter("Hey #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute("data-#{subject_name}")
      expect(link.attr("data-#{subject_name}")).to eq subject.id.to_s
    end
  end

  context 'when mentioning a resource' do
    it_behaves_like 'a reference containing an element node'
    it_behaves_like 'it contains a data- attribute'

    it "links to a resource" do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.send(:"#{subject_name}_url", subject)
    end

    it 'links to a resource with a period' do
      subject = create(subject_name.to_sym, name: 'alphA.Beta')

      doc = reference_filter("Hey #{get_reference(subject)}")
      expect(doc.css('a').length).to eq 1
    end

    it 'links to a resource with an underscore' do
      subject = create(subject_name.to_sym, name: 'ping_pong_king')

      doc = reference_filter("Hey #{get_reference(subject)}")
      expect(doc.css('a').length).to eq 1
    end

    it 'links to a resource with different case-sensitivity' do
      subject = create(subject_name.to_sym, name: 'RescueRanger')
      reference = get_reference(subject)

      doc = reference_filter("Hey #{reference.upcase}")
      expect(doc.css('a').length).to eq 1
      expect(doc.css('a').text).to eq(reference)
    end
  end

  it 'supports an :only_path context' do
    doc = reference_filter("Hey #{reference}", only_path: true)
    link = doc.css('a').first.attr('href')

    expect(link).not_to match %r{https?://}
    expect(link).to eq urls.send :"#{subject_name}_path", subject
  end

  describe 'referencing a resource in a link href' do
    let(:reference) { %(<a href="#{get_reference(subject)}">Some text</a>) }

    it_behaves_like 'it contains a data- attribute'

    it 'links to the resource' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.send :"#{subject_name}_url", subject
    end

    it 'links with adjacent text' do
      doc = reference_filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>Some text</a>\.\)})
    end
  end
end

RSpec.shared_examples 'HTML text with references' do
  let(:markdown_prepend) { "&lt;img src=\"\" onerror=alert('bug')&gt;" }

  it 'preserves escaped HTML text and adds valid references' do
    stub_commonmark_sourcepos_disabled
    reference = resource.to_reference(format: :name)

    doc = reference_filter("#{markdown_prepend}#{reference}")

    expect(doc.to_html).to start_with("<p>#{markdown_prepend}")
    expect(doc.text).to eq %(<img src="" onerror=alert('bug')>#{resource_text})
  end

  it 'preserves escaped HTML text if there are no valid references' do
    reference = "#{resource.class.reference_prefix}invalid"
    text = "#{markdown_prepend}#{reference}"

    doc = reference_filter(text)

    expect(doc.to_html).to include text
  end
end

RSpec.shared_examples 'a reference which does not unescape its content in data-original' do
  it 'does not remove a layer of escaping in data-original' do
    # We assert the expected resource.title so calling `it_behaves_like` blocks can better describe
    # the known behaviour around the resource.
    #
    # Some classes, like Label and Milestone, used to process their title in ways particularly relevant
    # to XSS; they no longer do, but we want to assert they haven't regressed in this manner.
    # If they did, these specs would fail in very opaque ways, as their preconditions would no longer hold.
    expect(resource.title).to eq(expected_resource_title)

    result = reference_filter("See #{reference}", context)

    expect(result.css('a').first.attr('href')).to eq(expected_href)

    # This is the important part.
    expect(result.css('a').first.attr('data-original')).to eq_html(reference)

    expect(result.content).to eq "See #{expected_replacement_text}"
  end
end

# Expects an input reference, and a filter instance to call #references_in on:
#   let(:reference) { range.to_reference }
#   let(:filter_instance) { described_class.new(nil, { project: nil }) }
#
# Optionally, you can override the expected replacement by setting `:expected_replacement`.
# In particular, if no replacement is expected, say:
#   let(:expected_replacement) { nil }
#
# See the doc comment on ReferenceFilter#references_in for a detailed discussion on
# this function's input, block, and output.
RSpec.shared_examples_for 'ReferenceFilter#references_in' do
  let(:replacement) do
    doc = Nokogiri::HTML.fragment("<a>link to label</a>")
    doc.css('a').first['href'] = '/destination'
    doc.to_html
  end

  let(:expected_replacement) { replacement }

  it "does not return input text unescaped" do
    text = "don't <b>unescape</b> #{reference} &lt;anything&gt;"

    html = filter_instance.references_in(text) do |match|
      # Special case: ProjectReferenceFilter will match "b>" and "/b>" from the above text.
      # This is correct. Let it pass through, translating text to HTML, like it normally would.
      #
      # Extremely special case: it'll also match "anything&gt;", though hopefully this will
      # become less necessary in the future. This is incorrect, but currently the case.
      # See Project.reference_postfix_escaped.
      next CGI.escapeHTML(match) if match == "b>" || match == "/b>" || match == "anything&gt;"

      expect(match).to eq(reference)
      replacement
    end

    case expected_replacement
    when NilClass
      expect(html).to be_nil
    when String
      expect(html).to eq_html("don't &lt;b&gt;unescape&lt;/b&gt; #{expected_replacement} &amp;lt;anything&amp;gt;")
    else
      raise ArgumentError, "expected_replacement should be nil or a String, not #{expected_replacement.class}"
    end
  end
end

# frozen_string_literal: true

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

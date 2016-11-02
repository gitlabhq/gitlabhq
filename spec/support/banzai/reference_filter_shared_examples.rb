# Specs for reference links containing HTML.
#
# Requires a reference:
#   let(:reference) { '#42' }
shared_examples 'a reference containing an element node' do
  let(:inner_html) { 'element <code>node</code> inside' }
  let(:reference_with_element) { %{<a href="#{reference}">#{inner_html}</a>} }

  it 'does not escape inner html' do
    doc = reference_filter(reference_with_element)
    expect(doc.children.first.inner_html).to eq(inner_html)
  end
end

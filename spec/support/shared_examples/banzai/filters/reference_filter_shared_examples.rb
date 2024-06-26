# frozen_string_literal: true

# Specs for reference links containing HTML.
#
# Requires a reference:
#   let(:reference) { '#42' }
RSpec.shared_examples 'a reference containing an element node' do
  let(:inner_html) { 'element <code>node</code> inside' }
  let(:reference_with_element) { %(<a href="#{reference}">#{inner_html}</a>) }

  it 'does not escape inner html' do
    doc = reference_filter(reference_with_element)

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
      expect(doc.css('a').first.attr('href')).to eq urls.send("#{subject_name}_url", subject)
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
    expect(link).to eq urls.send "#{subject_name}_path", subject
  end

  describe 'referencing a resource in a link href' do
    let(:reference) { %(<a href="#{get_reference(subject)}">Some text</a>) }

    it_behaves_like 'it contains a data- attribute'

    it 'links to the resource' do
      doc = reference_filter("Hey #{reference}")
      expect(doc.css('a').first.attr('href')).to eq urls.send "#{subject_name}_url", subject
    end

    it 'links with adjacent text' do
      doc = reference_filter("Mention me (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>Some text</a>\.\)})
    end
  end
end

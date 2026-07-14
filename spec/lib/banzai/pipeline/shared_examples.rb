# frozen_string_literal: true

# Verifies that the pipeline applies HeadingLocalizationFilter to heading anchors.
#
# Each pipeline that includes HeadingLocalizationFilter must wire this example.
# The caller supplies:
#   - heading_input: markup text (or pre-rendered HTML) containing one heading
#   - heading_text:  the plain-text content of that heading (used in the expected aria-label)
#
# Example usage:
#   it_behaves_like 'applies heading localization filter',
#     heading_input: '## My Heading',
#     heading_text: 'My Heading'
RSpec.shared_examples 'applies heading localization filter' do |heading_input:, heading_text:|
  it 'localizes heading anchor aria-labels via HeadingLocalizationFilter', :aggregate_failures do
    allow_next_instance_of(Banzai::Filter::HeadingLocalizationFilter) do |instance|
      allow(instance).to receive(:_).and_return("Localized '%{heading}'")
    end

    html = described_class.to_html(heading_input, { project: nil })
    doc = Nokogiri::HTML5.fragment(html)
    anchor = doc.css('h1 a.anchor, h2 a.anchor, h3 a.anchor, h4 a.anchor, h5 a.anchor, h6 a.anchor').first

    expect(anchor).to be_present
    expect(anchor['aria-label']).to eq("Localized '#{heading_text}'")
  end
end

RSpec.shared_examples 'a single line pipeline' do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  it 'does not process markdown' do
    text = '_italic_'

    expect(to_html(text)).to eq(text)
  end

  it 'escapes HTML' do
    text = '<p>Hello<br>World</p>'

    expect(to_html(text)).to eq('&lt;p&gt;Hello&lt;br&gt;World&lt;/p&gt;')
  end

  it 'handles emojis and autolinking', :aggregate_failures do
    text = ':smile: using http://example.com'
    result = to_html(text)

    expect(result).to include('gl-emoji')
    expect(result).to include('<a href="http://example.com"')
  end

  it 'recognizes references', :aggregate_failures do
    text = "Issue #{issue.to_reference}, User #{user.to_reference}"
    result = to_html(text)

    expect(result).to include('data-reference-type="issue"')
    expect(result).to include('data-reference-type="user"')
  end

  def to_html(text)
    described_class.to_html(text, project: project, pipeline: :single_line)
  end
end

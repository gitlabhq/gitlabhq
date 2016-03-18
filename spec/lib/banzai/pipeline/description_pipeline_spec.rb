require 'rails_helper'

describe Banzai::Pipeline::DescriptionPipeline do
  def parse(html)
    # When we pass HTML to Redcarpet, it gets wrapped in `p` tags...
    # ...except when we pass it pre-wrapped text. Rabble rabble.
    unwrap = !html.start_with?('<p>')

    output = described_class.to_html(html, project: spy)

    output.gsub!(%r{\A<p>(.*)</p>(.*)\z}, '\1\2') if unwrap

    output
  end

  it 'uses a limited whitelist' do
    doc = parse('# Description')

    expect(doc.strip).to eq 'Description'
  end

  %w(pre code img ol ul li).each do |elem|
    it "removes '#{elem}' elements" do
      act = "<#{elem}>Description</#{elem}>"

      expect(parse(act).strip).to eq 'Description'
    end
  end

  %w(b i strong em a ins del sup sub p).each do |elem|
    it "still allows '#{elem}' elements" do
      exp = act = "<#{elem}>Description</#{elem}>"

      expect(parse(act).strip).to eq exp
    end
  end
end

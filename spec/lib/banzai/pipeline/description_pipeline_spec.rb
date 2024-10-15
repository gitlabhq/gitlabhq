# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::DescriptionPipeline, feature_category: :markdown do
  let_it_be(:project) { create(:project) }

  def parse(html)
    # When we pass HTML to Redcarpet, it gets wrapped in `p` tags...
    # ...except when we pass it pre-wrapped text. Rabble rabble.
    unwrap = !html.start_with?('<p ')

    output = described_class.to_html(html, project: project)

    output.gsub!(%r{\A<p dir="auto">(.*)</p>(.*)\z}, '\1\2') if unwrap

    output
  end

  before do
    stub_commonmark_sourcepos_disabled
  end

  it_behaves_like 'sanitize pipeline'

  it 'uses a limited allowlist' do
    doc = parse('# Description')

    expect(doc.strip).to eq 'Description'
  end

  %w[pre code img ol ul li].each do |elem|
    it "removes '#{elem}' elements" do
      act = "<#{elem}>Description</#{elem}>"

      expect(parse(act).strip).to eq 'Description'
    end
  end

  %w[b i strong em a ins del sup sub].each do |elem|
    it "still allows '#{elem}' elements" do
      exp = act = "<#{elem}>Description</#{elem}>"

      expect(parse(act).strip).to eq exp
    end
  end

  it "still allows 'p' elements" do
    exp = act = "<p dir=\"auto\">Description</p>"

    expect(parse(act).strip).to eq exp
  end
end

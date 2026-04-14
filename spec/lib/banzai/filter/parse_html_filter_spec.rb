# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ParseHtmlFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'returns a nokogiri doc' do
    doc = filter('<h1>test</h2')

    expect(doc).to be_a(Nokogiri::HTML5::DocumentFragment)
  end
end

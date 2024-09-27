# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ConvertTextToDocFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'returns a nokogiri doc' do
    doc = filter('<h1>test</h2')

    expect(doc.is_a?(Nokogiri::HTML4::DocumentFragment)).to be_truthy
  end
end

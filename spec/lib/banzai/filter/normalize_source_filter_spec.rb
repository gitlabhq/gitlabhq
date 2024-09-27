# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::NormalizeSourceFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'removes the UTF8 BOM from the beginning of the text' do
    content = "\xEF\xBB\xBF---"

    output = filter(content)

    expect(output).to match '---'
  end

  it 'does not remove those characters from anywhere else in the text' do
    content = <<~MD
      \xEF\xBB\xBF---
      \xEF\xBB\xBF---
    MD

    output = filter(content)

    expect(output).to match "---\n\xEF\xBB\xBF---\n"
  end
end

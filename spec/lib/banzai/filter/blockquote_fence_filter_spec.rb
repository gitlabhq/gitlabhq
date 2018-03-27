require 'rails_helper'

describe Banzai::Filter::BlockquoteFenceFilter do
  include FilterSpecHelper

  it 'converts blockquote fences to blockquote lines' do
    content = File.read(Rails.root.join('spec/fixtures/blockquote_fence_before.md'))
    expected = File.read(Rails.root.join('spec/fixtures/blockquote_fence_after.md'))

    output = filter(content)

    expect(output).to eq(expected)
  end
end

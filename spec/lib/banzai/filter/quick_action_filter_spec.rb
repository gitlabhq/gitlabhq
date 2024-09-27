# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::QuickActionFilter, feature_category: :markdown do
  let(:result) { {} }

  it 'detects action in paragraph' do
    described_class.call('<p data-sourcepos="1:1-2:3">/quick</p>', {}, result)

    expect(result[:quick_action_paragraphs]).to match_array [{ start_line: 0, end_line: 1 }]
  end

  it 'does not detect action in paragraph if no sourcepos' do
    described_class.call('<p>/quick</p>', {}, result)

    expect(result[:quick_action_paragraphs]).to be_empty
  end

  it 'does not detect action in blockquote' do
    described_class.call('<blockquote data-sourcepos="1:1-1:1">/quick</blockquote>', {}, result)

    expect(result[:quick_action_paragraphs]).to be_empty
  end

  it 'does not detect action in html block' do
    described_class.call('<li data-sourcepos="1:1-1:1">/quick</li>', {}, result)

    expect(result[:quick_action_paragraphs]).to be_empty
  end

  it 'does not detect action in code block' do
    described_class.call('<code data-sourcepos="1:1-1:1">/quick</code>', {}, result)

    expect(result[:quick_action_paragraphs]).to be_empty
  end
end

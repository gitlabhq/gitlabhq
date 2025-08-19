# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ColorFilter, :lib, feature_category: :markdown do
  include FilterSpecHelper

  let(:color) { '#F00' }
  let(:color_chip_selector) { 'code > span.gfm-color_chip > span' }

  ['#123', '#1234', '#123456', '#12345678',
   'rgb(0,0,0)', 'RGB(0, 0, 0)', 'rgba(0,0,0,1)', 'RGBA(0,0,0,0.7)',
   'hsl(270,30%,50%)', 'HSLA(270, 30%, 50%, .7)'].each do |color|
    it "inserts color chip for supported color format #{color}" do
      content = code_tag(color)
      doc = filter(content)
      color_chip = doc.at_css(color_chip_selector)

      expect(color_chip.content).to be_empty
      expect(color_chip.parent[:class]).to eq 'gfm-color_chip'
      expect(color_chip[:style]).to eq "background-color: #{color};"
    end
  end

  ['\#123', '\#1234', '\#123456', '\#12345678',
   '\rgb(0,0,0)', '\RGB(0, 0, 0)', '\rgba(0,0,0,1)', '\RGBA(0,0,0,0.7)',
   '\hsl(270,30%,50%)', '\HSLA(270, 30%, 50%, .7)'].each do |escaped_color|
    it "does not insert color chip and unescapes escaped color #{escaped_color}" do
      content = code_tag(escaped_color)
      doc = filter(content)
      unescaped = escaped_color.delete_prefix('\\')
      expect(doc.css(color_chip_selector).size).to be_zero
      expect(doc.at_css('code').content).to eq(unescaped)
    end
  end

  it 'ignores valid color code without backticks(code tags)' do
    doc = filter(color)

    expect(doc.css('span.gfm-color_chip').size).to be_zero
  end

  it 'ignores valid color code with prepended space' do
    content = code_tag(' ' + color)
    doc = filter(content)

    expect(doc.css(color_chip_selector).size).to be_zero
  end

  it 'ignores valid color code with appended space' do
    content = code_tag(color + ' ')
    doc = filter(content)

    expect(doc.css(color_chip_selector).size).to be_zero
  end

  it 'ignores valid color code surrounded by spaces' do
    content = code_tag(' ' + color + ' ')
    doc = filter(content)

    expect(doc.css(color_chip_selector).size).to be_zero
  end

  it 'ignores invalid color code' do
    invalid_color = '#BAR'
    content = code_tag(invalid_color)
    doc = filter(content)

    expect(doc.css(color_chip_selector).size).to be_zero
  end

  it_behaves_like 'pipeline timing check'

  def code_tag(string)
    "<code>#{string}</code>"
  end
end

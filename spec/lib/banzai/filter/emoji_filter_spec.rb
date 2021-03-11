# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::EmojiFilter do
  include FilterSpecHelper

  it_behaves_like 'emoji filter' do
    let(:emoji_name) { ':+1:' }
  end

  it 'replaces supported name emoji' do
    doc = filter('<p>:heart:</p>')
    expect(doc.css('gl-emoji').first.text).to eq '❤'
  end

  it 'replaces supported unicode emoji' do
    doc = filter('<p>❤️</p>')
    expect(doc.css('gl-emoji').first.text).to eq '❤'
  end

  it 'ignores unicode versions of trademark, copyright, and registered trademark' do
    exp = act = '<p>™ © ®</p>'
    doc = filter(act)
    expect(doc.to_html).to match Regexp.escape(exp)
  end

  it 'replaces name versions of trademark, copyright, and registered trademark' do
    doc = filter('<p>:tm: :copyright: :registered:</p>')

    expect(doc.css('gl-emoji')[0].text).to eq '™'
    expect(doc.css('gl-emoji')[1].text).to eq '©'
    expect(doc.css('gl-emoji')[2].text).to eq '®'
  end

  it 'correctly encodes the URL' do
    doc = filter('<p>:+1:</p>')
    expect(doc.css('gl-emoji').first.text).to eq '👍'
  end

  it 'correctly encodes unicode to the URL' do
    doc = filter('<p>👍</p>')
    expect(doc.css('gl-emoji').first.text).to eq '👍'
  end

  it 'matches at the start of a string' do
    doc = filter(':+1:')
    expect(doc.css('gl-emoji').size).to eq 1
  end

  it 'unicode matches at the start of a string' do
    doc = filter("'👍'")
    expect(doc.css('gl-emoji').size).to eq 1
  end

  it 'matches at the end of a string' do
    doc = filter('This gets a :-1:')
    expect(doc.css('gl-emoji').size).to eq 1
  end

  it 'unicode matches at the end of a string' do
    doc = filter('This gets a 👍')
    expect(doc.css('gl-emoji').size).to eq 1
  end

  it 'unicode matches with adjacent text' do
    doc = filter('+1 (👍)')
    expect(doc.css('gl-emoji').size).to eq 1
  end

  it 'does not match multiple emoji in a row' do
    doc = filter(':see_no_evil::hear_no_evil::speak_no_evil:')
    expect(doc.css('gl-emoji').size).to eq 0
  end

  it 'unicode matches multiple emoji in a row' do
    doc = filter("'🙈🙉🙊'")
    expect(doc.css('gl-emoji').size).to eq 3
  end

  it 'mixed matches multiple emoji in a row' do
    doc = filter("'🙈:see_no_evil:🙉:hear_no_evil:🙊:speak_no_evil:'")
    expect(doc.css('gl-emoji').size).to eq 6
  end

  it 'has a data-name attribute' do
    doc = filter(':-1:')
    expect(doc.css('gl-emoji').first.attr('data-name')).to eq 'thumbsdown'
  end

  it 'has a data-unicode-version attribute' do
    doc = filter(':-1:')
    expect(doc.css('gl-emoji').first.attr('data-unicode-version')).to eq '6.0'
  end

  it 'unicode keeps whitespace intact' do
    doc = filter('This deserves a 🎱, big time.')

    expect(doc.to_html).to match(/^This deserves a <gl-emoji.+>, big time\.\z/)
  end
end

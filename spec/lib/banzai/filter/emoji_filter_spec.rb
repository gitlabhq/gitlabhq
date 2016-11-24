require 'spec_helper'

describe Banzai::Filter::EmojiFilter, lib: true do
  include FilterSpecHelper

  before do
    @original_asset_host = ActionController::Base.asset_host
    ActionController::Base.asset_host = 'https://foo.com'
  end

  after do
    ActionController::Base.asset_host = @original_asset_host
  end

  it 'replaces supported name emoji' do
    doc = filter('<p>:heart:</p>')
    expect(doc.css('img').first.attr('src')).to eq 'https://foo.com/assets/2764.png'
  end

  it 'replaces supported unicode emoji' do
    doc = filter('<p>❤️</p>')
    expect(doc.css('img').first.attr('src')).to eq 'https://foo.com/assets/2764.png'
  end

  it 'ignores unsupported emoji' do
    exp = act = '<p>:foo:</p>'
    doc = filter(act)
    expect(doc.to_html).to match Regexp.escape(exp)
  end

  it 'correctly encodes the URL' do
    doc = filter('<p>:+1:</p>')
    expect(doc.css('img').first.attr('src')).to eq 'https://foo.com/assets/1F44D.png'
  end

  it 'correctly encodes unicode to the URL' do
    doc = filter('<p>👍</p>')
    expect(doc.css('img').first.attr('src')).to eq 'https://foo.com/assets/1F44D.png'
  end

  it 'matches at the start of a string' do
    doc = filter(':+1:')
    expect(doc.css('img').size).to eq 1
  end

  it 'unicode matches at the start of a string' do
    doc = filter("'👍'")
    expect(doc.css('img').size).to eq 1
  end

  it 'matches at the end of a string' do
    doc = filter('This gets a :-1:')
    expect(doc.css('img').size).to eq 1
  end

  it 'unicode matches at the end of a string' do
    doc = filter('This gets a 👍')
    expect(doc.css('img').size).to eq 1
  end

  it 'matches with adjacent text' do
    doc = filter('+1 (:+1:)')
    expect(doc.css('img').size).to eq 1
  end

  it 'unicode matches with adjacent text' do
    doc = filter('+1 (👍)')
    expect(doc.css('img').size).to eq 1
  end

  it 'matches multiple emoji in a row' do
    doc = filter(':see_no_evil::hear_no_evil::speak_no_evil:')
    expect(doc.css('img').size).to eq 3
  end

  it 'unicode matches multiple emoji in a row' do
    doc = filter("'🙈🙉🙊'")
    expect(doc.css('img').size).to eq 3
  end

  it 'mixed matches multiple emoji in a row' do
    doc = filter("'🙈:see_no_evil:🙉:hear_no_evil:🙊:speak_no_evil:'")
    expect(doc.css('img').size).to eq 6
  end

  it 'has a title attribute' do
    doc = filter(':-1:')
    expect(doc.css('img').first.attr('title')).to eq ':-1:'
  end

  it 'unicode has a title attribute' do
    doc = filter("'👎'")
    expect(doc.css('img').first.attr('title')).to eq ':thumbsdown:'
  end

  it 'has an alt attribute' do
    doc = filter(':-1:')
    expect(doc.css('img').first.attr('alt')).to eq ':-1:'
  end

  it 'unicode has an alt attribute' do
    doc = filter("'👎'")
    expect(doc.css('img').first.attr('alt')).to eq ':thumbsdown:'
  end

  it 'has an align attribute' do
    doc = filter(':8ball:')
    expect(doc.css('img').first.attr('align')).to eq 'absmiddle'
  end

  it 'unicode has an align attribute' do
    doc = filter("'🎱'")
    expect(doc.css('img').first.attr('align')).to eq 'absmiddle'
  end

  it 'has an emoji class' do
    doc = filter(':cat:')
    expect(doc.css('img').first.attr('class')).to eq 'emoji'
  end

  it 'unicode has an emoji class' do
    doc = filter("'🐱'")
    expect(doc.css('img').first.attr('class')).to eq 'emoji'
  end

  it 'has height and width attributes' do
    doc = filter(':dog:')
    img = doc.css('img').first

    expect(img.attr('width')).to eq '20'
    expect(img.attr('height')).to eq '20'
  end

  it 'unicode has height and width attributes' do
    doc = filter("'🐶'")
    img = doc.css('img').first

    expect(img.attr('width')).to eq '20'
    expect(img.attr('height')).to eq '20'
  end

  it 'keeps whitespace intact' do
    doc = filter('This deserves a :+1:, big time.')

    expect(doc.to_html).to match(/^This deserves a <img.+>, big time\.\z/)
  end

  it 'unicode keeps whitespace intact' do
    doc = filter('This deserves a 🎱, big time.')

    expect(doc.to_html).to match(/^This deserves a <img.+>, big time\.\z/)
  end

  it 'uses a custom asset_root context' do
    root = Gitlab.config.gitlab.url + 'gitlab/root'

    doc = filter(':smile:', asset_root: root)
    expect(doc.css('img').first.attr('src')).to start_with(root)
  end

  it 'uses a custom asset_host context' do
    ActionController::Base.asset_host = 'https://cdn.example.com'

    doc = filter(':frowning:', asset_host: 'https://this-is-ignored-i-guess?')
    expect(doc.css('img').first.attr('src')).to start_with('https://cdn.example.com')
  end

  it 'uses a custom asset_root context' do
    root = Gitlab.config.gitlab.url + 'gitlab/root'

    doc = filter("'🎱'", asset_root: root)
    expect(doc.css('img').first.attr('src')).to start_with(root)
  end

  it 'uses a custom asset_host context' do
    ActionController::Base.asset_host = 'https://cdn.example.com'

    doc = filter("'🎱'", asset_host: 'https://this-is-ignored-i-guess?')
    expect(doc.css('img').first.attr('src')).to start_with('https://cdn.example.com')
  end
end

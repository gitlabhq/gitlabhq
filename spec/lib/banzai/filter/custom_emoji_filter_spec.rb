require 'spec_helper'

describe Banzai::Filter::CustomEmojiFilter do
  include FilterSpecHelper

  let(:project) { create(:project) }

  before do
    custom_emoji = create(:custom_emoji, name: 'awesome_banana', namespace: project.namespace)

    allow_any_instance_of(Namespace).to receive(:custom_emoji_url_by_name).and_return({
      custom_emoji.name => custom_emoji.url
    })
  end

  it 'replaces supported name custom emoji' do
    doc = filter('<p>:awesome_banana:</p>', project: project)

    expect(doc.css('img').first.attributes['alt'].value).to eq 'awesome_banana'
  end

  it 'ignores unsupported custom emoji' do
    exp = act = '<p>:foo:</p>'
    doc = filter(act)

    expect(doc.to_html).to match Regexp.escape(exp)
  end

  it 'correctly encodes the URL' do
    doc = filter('<p>:awesome_banana:</p>')

    expect(doc.css('img').first.attributes['src'].value).to include('/uploads/-/system/custom_emoji/namespace3/3/dk.png')
  end

  it 'matches with adjacent text' do
    doc = filter('awesome_banana (:awesome_banana:)')

    expect(doc.css('img').size).to eq 1
  end
end

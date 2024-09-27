# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::CustomEmojiFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:custom_emoji) { create(:custom_emoji, name: 'tanuki', group: group) }
  let_it_be(:custom_emoji2) { create(:custom_emoji, name: 'happy_tanuki', group: group, file: 'https://foo.bar/happy.png') }

  it_behaves_like 'emoji filter' do
    let(:emoji_name) { ':tanuki:' }
  end

  it 'replaces supported name custom emoji' do
    doc = filter('<p>:tanuki:</p>', project: project)

    expect(doc.css('gl-emoji').first.attributes['title'].value).to eq('tanuki')
  end

  it 'correctly uses the custom emoji URL' do
    doc = filter('<p>:tanuki:</p>')

    expect(doc.css('gl-emoji').first.attributes['data-fallback-src'].value).to eq(custom_emoji.file)
  end

  it 'matches multiple same custom emoji' do
    doc = filter(':tanuki: :tanuki:')

    expect(doc.css('gl-emoji').size).to eq 2
  end

  it 'matches multiple custom emoji' do
    doc = filter(':tanuki: (:happy_tanuki:)')

    expect(doc.css('gl-emoji').size).to eq 2
  end

  it 'does not match enclosed colons' do
    doc = filter('tanuki:tanuki:')

    expect(doc.css('gl-emoji').size).to be 0
  end

  it 'does not match an unknown emoji' do
    doc = filter(':tanuki: :tanooki:')

    expect(doc.css('gl-emoji').size).to be 1
  end

  it 'does not do N+1 query' do
    create(:custom_emoji, name: 'party-parrot', group: group)

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      filter('<p>:tanuki:</p>')
    end

    expect do
      filter('<p>:tanuki:</p> <p>:party-parrot:</p>')
    end.not_to exceed_all_query_limit(control)
  end

  it 'uses custom emoji from ancestor group' do
    subgroup = create(:group, parent: group)

    doc = filter('<p>:tanuki:</p>', group: subgroup)

    expect(doc.css('gl-emoji').size).to eq 1
  end

  context 'when asset proxy is configured' do
    before do
      stub_asset_proxy_setting(
        enabled: true,
        secret_key: 'shared-secret',
        url: 'https://assets.example.com'
      )
    end

    it 'uses the proxied url' do
      doc = filter('<p>:tanuki:</p>')

      expect(doc.css('gl-emoji').first.attributes['data-fallback-src'].value).to start_with('https://assets.example.com')
    end
  end

  it_behaves_like 'pipeline timing check'
  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { ':tanuki: :tanuki: :tanuki:' }
    let(:ends_with) { '</gl-emoji> :tanuki:' }
  end
end

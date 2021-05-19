# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::CustomEmojiFilter do
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
    expect(doc.css('gl-emoji img').size).to eq 1
  end

  it 'correctly uses the custom emoji URL' do
    doc = filter('<p>:tanuki:</p>')

    expect(doc.css('img').first.attributes['src'].value).to eq(custom_emoji.file)
  end

  it 'matches multiple same custom emoji' do
    doc = filter(':tanuki: :tanuki:')

    expect(doc.css('img').size).to eq 2
  end

  it 'matches multiple custom emoji' do
    doc = filter(':tanuki: (:happy_tanuki:)')

    expect(doc.css('img').size).to eq 2
  end

  it 'does not match enclosed colons' do
    doc = filter('tanuki:tanuki:')

    expect(doc.css('img').size).to be 0
  end

  it 'does not do N+1 query' do
    create(:custom_emoji, name: 'party-parrot', group: group)

    control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      filter('<p>:tanuki:</p>')
    end

    expect do
      filter('<p>:tanuki:</p> <p>:party-parrot:</p>')
    end.not_to exceed_all_query_limit(control_count.count)
  end
end

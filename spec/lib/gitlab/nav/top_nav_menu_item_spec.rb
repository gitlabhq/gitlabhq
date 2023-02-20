# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::Gitlab::Nav::TopNavMenuItem, feature_category: :navigation do
  describe '.build' do
    it 'builds a hash from the given args' do
      item = {
        id: 'id',
        title: 'Title',
        active: true,
        icon: 'icon',
        href: 'href',
        view: 'view',
        css_class: 'css_class',
        data: {},
        emoji: 'smile'
      }

      expect(described_class.build(**item)).to eq(item.merge(type: :item))
    end
  end
end

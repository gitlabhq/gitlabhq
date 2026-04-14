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
        partial: 'groups/some_view_partial_file',
        component: '_some_component_used_as_a_trigger_for_frontend_dropdown_item_render_'
      }

      result = described_class.build(**item)

      expect(result).to eq(item.merge(type: :item))
    end
  end
end

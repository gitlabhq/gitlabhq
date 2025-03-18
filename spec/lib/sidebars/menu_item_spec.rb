# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Sidebars::MenuItem, feature_category: :navigation do
  let(:title) { 'foo' }
  let(:html_options) { {} }
  let(:extra) { {} }
  let(:menu_item) { described_class.new(title: title, active_routes: {}, link: '', container_html_options: html_options, **extra) }

  it 'includes by default aria-label attribute set to the title' do
    expect(menu_item.container_html_options).to eq({ aria: { label: title } })
  end

  context 'when aria-label is overridde during initialization' do
    let(:html_options) { { aria: { label: 'bar' } } }

    it 'sets the aria-label to the new attribute' do
      expect(menu_item.container_html_options).to eq html_options
    end
  end

  describe "#serialize_for_super_sidebar" do
    let(:html_options) { { class: 'custom-class' } }
    let(:extra) { { avatar: '/avatar.png', entity_id: 123 } }

    subject { menu_item.serialize_for_super_sidebar }

    it 'includes custom CSS classes' do
      expect(subject[:link_classes]).to be('custom-class')
    end

    it 'includes avatar data' do
      expect(subject[:avatar]).to be('/avatar.png')
      expect(subject[:entity_id]).to be(123)
    end

    context 'with pill data' do
      let(:extra) { { has_pill: true, pill_count: '5', pill_count_field: 'countField' } }

      it 'includes pill count data' do
        expect(subject[:pill_count]).to eq('5')
        expect(subject[:pill_count_field]).to eq('countField')
      end
    end
  end

  describe '#render?' do
    subject(:menu_item) do
      described_class.new(
        title: 'Test Item',
        link: '/test',
        active_routes: []
      )
    end

    context 'when render is not set' do
      it { is_expected.to be_render }
    end

    context 'when render is explicitly set' do
      context 'when set to false' do
        before do
          menu_item.render = false
        end

        it { is_expected.not_to be_render }
      end

      context 'when set to true' do
        before do
          menu_item.render = true
        end

        it { is_expected.to be_render }
      end
    end
  end
end

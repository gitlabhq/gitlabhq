# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/_gl_toggle.html.haml' do
  context 'defaults' do
    before do
      render partial: 'shared/gl_toggle', locals: {
        classes: '.js-gl-toggle'
      }
    end

    it 'does not set a name' do
      expect(rendered).not_to have_selector('[data-name]')
    end

    it 'sets default is-checked attributes' do
      expect(rendered).to have_selector('[data-is-checked="false"]')
    end

    it 'sets default disabled attributes' do
      expect(rendered).to have_selector('[data-disabled="false"]')
    end

    it 'sets default is-loading attributes' do
      expect(rendered).to have_selector('[data-is-loading="false"]')
    end

    it 'does not set a label' do
      expect(rendered).not_to have_selector('[data-label]')
    end

    it 'does not set a label position' do
      expect(rendered).not_to have_selector('[data-label-position]')
    end
  end

  context 'with custom options' do
    before do
      render partial: 'shared/gl_toggle', locals: {
        classes: 'js-custom-gl-toggle',
        name: 'toggle-name',
        is_checked: true,
        disabled: true,
        is_loading: true,
        label: 'Custom label',
        label_position: 'top',
        data: {
          foo: 'bar'
        }
      }
    end

    it 'sets the custom class' do
      expect(rendered).to have_selector('.js-custom-gl-toggle')
    end

    it 'sets the custom name' do
      expect(rendered).to have_selector('[data-name="toggle-name"]')
    end

    it 'sets the custom is-checked attributes' do
      expect(rendered).to have_selector('[data-is-checked="true"]')
    end

    it 'sets the custom disabled attributes' do
      expect(rendered).to have_selector('[data-disabled="true"]')
    end

    it 'sets the custom is-loading attributes' do
      expect(rendered).to have_selector('[data-is-loading="true"]')
    end

    it 'sets the custom label' do
      expect(rendered).to have_selector('[data-label="Custom label"]')
    end

    it 'sets the cutom label position' do
      expect(rendered).to have_selector('[data-label-position="top"]')
    end

    it 'sets cutom data attributes' do
      expect(rendered).to have_selector('[data-foo="bar"]')
    end
  end
end

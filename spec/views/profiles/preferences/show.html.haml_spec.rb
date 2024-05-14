# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/preferences/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create_default(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'appearance' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#appearance')
    end
  end

  context 'navigation theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#navigation-theme')
    end
  end

  context 'syntax highlighting theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#syntax-highlighting-theme')
    end
  end

  context 'behavior' do
    before do
      render
    end

    it 'has option for Render whitespace characters in the Web IDE' do
      expect(rendered).to have_unchecked_field('Render whitespace characters in the Web IDE')
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#behavior')
    end

    it 'has helpful homepage setup guidance' do
      expect(rendered).to have_selector('[data-label="Homepage"]')
      expect(rendered).to have_selector("[data-description=" \
                                        "'Choose what content you want to see by default on your homepage.']")
    end
  end

  context 'localization' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#localization')
    end
  end
end

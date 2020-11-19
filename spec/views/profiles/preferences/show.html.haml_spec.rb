# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/preferences/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'navigation theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#navigation-theme')
    end

    it 'has correct stylesheet tags' do
      Gitlab::Themes.each do |theme|
        next unless theme.css_filename

        expect(rendered).to have_selector("link[href*=\"themes/#{theme.css_filename}\"]", visible: false)
      end
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
      expect(rendered).to have_field('Homepage content')
      expect(rendered).to have_content('Choose what content you want to see on your homepage.')
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

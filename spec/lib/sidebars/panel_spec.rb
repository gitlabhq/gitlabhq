# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Panel do
  let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }
  let(:panel) { Sidebars::Panel.new(context) }
  let(:menu1) { Sidebars::Menu.new(context) }
  let(:menu2) { Sidebars::Menu.new(context) }

  describe '#renderable_menus' do
    it 'returns only renderable menus' do
      panel.add_menu(menu1)
      panel.add_menu(menu2)

      allow(menu1).to receive(:render?).and_return(true)
      allow(menu2).to receive(:render?).and_return(false)

      expect(panel.renderable_menus).to eq([menu1])
    end
  end

  describe '#has_renderable_menus?' do
    it 'returns false when no renderable menus' do
      expect(panel.has_renderable_menus?).to be false
    end

    it 'returns true when no renderable menus' do
      panel.add_menu(menu1)

      expect(panel.has_renderable_menus?).to be true
    end
  end
end

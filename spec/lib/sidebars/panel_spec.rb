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
      allow(menu1).to receive(:render?).and_return(true)

      panel.add_menu(menu1)

      expect(panel.has_renderable_menus?).to be true
    end
  end

  describe '#add_element' do
    it 'adds the element to the last position of the list' do
      list = [1, 2]

      panel.add_element(list, 3)

      expect(list).to eq([1, 2, 3])
    end

    it 'does not add nil elements' do
      list = []

      panel.add_element(list, nil)

      expect(list).to be_empty
    end
  end

  describe '#insert_element_before' do
    let(:user) { build(:user) }
    let(:list) { [1, user] }

    it 'adds element before the specific element class' do
      panel.insert_element_before(list, User, 2)

      expect(list).to eq [1, 2, user]
    end

    it 'does not add nil elements' do
      panel.insert_element_before(list, User, nil)

      expect(list).to eq [1, user]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the top of the list' do
        panel.insert_element_before(list, Project, 2)

        expect(list).to eq [2, 1, user]
      end
    end
  end

  describe '#insert_element_after' do
    let(:user) { build(:user) }
    let(:list) { [1, user] }

    it 'adds element after the specific element class' do
      panel.insert_element_after(list, Integer, 2)

      expect(list).to eq [1, 2, user]
    end

    it 'does not add nil elements' do
      panel.insert_element_after(list, Integer, nil)

      expect(list).to eq [1, user]
    end

    context 'when reference element does not exist' do
      it 'adds the element to the end of the list' do
        panel.insert_element_after(list, Project, 2)

        expect(list).to eq [1, user, 2]
      end
    end
  end

  describe '#replace_element' do
    let(:user) { build(:user) }
    let(:list) { [1, user] }

    it 'replace existing element in the list' do
      panel.replace_element(list, Integer, 2)

      expect(list).to eq [2, user]
    end

    it 'does not add nil elements' do
      panel.replace_element(list, Integer, nil)

      expect(list).to eq [1, user]
    end

    it 'does not add the element if the other element is not found' do
      panel.replace_element(list, Project, 2)

      expect(list).to eq [1, user]
    end
  end
end

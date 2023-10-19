# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Menus::SettingsMenu, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }

  let(:user) { build(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: organization) }
  let(:items) { subject.instance_variable_get(:@items) }

  subject { described_class.new(context) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(_("Settings"))
    expect(subject.sprite_icon).to eq("settings")
  end

  describe '#render?' do
    context 'when user is signed out' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when `current_user` is an admin', :enable_admin_mode do
      let(:user) { build(:admin) }

      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when `current_user` not an admin' do
      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

    describe 'General' do
      let(:item_id) { :organization_settings_general }

      it { is_expected.not_to be_nil }
    end
  end
end

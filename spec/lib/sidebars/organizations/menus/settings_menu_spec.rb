# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Menus::SettingsMenu, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }

  let(:user) { build(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: organization) }

  subject { described_class.new(context) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(_("Settings"))
    expect(subject.sprite_icon).to eq("settings")
  end

  describe '#render?' do
    it 'does not render without any menu items in CE' do
      expect(subject.render?).to be false
    end
  end
end

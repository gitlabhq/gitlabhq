# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::AccessMenu, feature_category: :navigation do
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  describe 'Menu Items' do
    subject(:items) { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

    describe 'Password menu', feature_category: :system_access do
      let(:item_id) { :password }

      context 'when the user can change the password' do
        it { is_expected.to be_present }
      end

      context 'when the user can not change the password' do
        before do
          allow(user).to receive(:allow_password_authentication?).and_return(false)
        end

        it { is_expected.not_to be_present }
      end
    end

    describe 'Personal access tokens menu', feature_category: :system_access do
      let(:item_id) { :access_tokens }

      it { is_expected.to be_present }
    end

    describe 'SSH keys menu', feature_category: :system_access do
      let(:item_id) { :ssh_keys }

      it { is_expected.to be_present }
    end

    describe 'GPG keys menu', feature_category: :system_access do
      let(:item_id) { :gpg_keys }

      it { is_expected.to be_present }
    end

    describe 'Applications menu', feature_category: :system_access do
      let(:item_id) { :applications }

      it { is_expected.to be_present }
    end

    describe 'Authentication log menu', feature_category: :system_access do
      let(:item_id) { :authentication_log }

      it { is_expected.to be_present }
    end

    describe 'Active sessions menu', feature_category: :system_access do
      let(:item_id) { :active_sessions }

      it { is_expected.to be_present }
    end
  end
end

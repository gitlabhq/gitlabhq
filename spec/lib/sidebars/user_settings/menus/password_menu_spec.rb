# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::PasswordMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/password',
    title: _('Password'),
    icon: 'lock',
    active_routes: { controller: :passwords }

  describe '#render?' do
    subject { described_class.new(context) }

    let_it_be(:user) { build(:user) }
    let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

    context 'when password authentication is enabled' do
      before do
        allow(user).to receive(:allow_password_authentication?).and_return(true)
      end

      it 'renders' do
        expect(subject.render?).to be true
      end
    end

    context 'when password authentication is disabled' do
      before do
        allow(user).to receive(:allow_password_authentication?).and_return(false)
      end

      it 'renders' do
        expect(subject.render?).to be false
      end
    end
  end
end

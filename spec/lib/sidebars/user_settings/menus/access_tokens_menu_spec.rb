# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::AccessTokensMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/user_settings/personal_access_tokens',
    title: _('Access tokens'),
    icon: 'token',
    active_routes: { controller: :personal_access_tokens }

  describe '#render?' do
    subject { described_class.new(context) }

    let_it_be(:user) { build(:user) }

    context 'when personal access tokens are disabled in the instance' do
      before do
        allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end

    context 'when personal access tokens are enabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: false)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'renders' do
          expect(subject.render?).to be true
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end
  end
end

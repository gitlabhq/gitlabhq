# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPresenter do
  let_it_be(:user) { create(:user) }

  let(:current_user) { user }

  subject(:presenter) { described_class.new(user, current_user: current_user) }

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{user.username}") }
  end

  describe '#web_url' do
    it { expect(presenter.web_url).to eq("http://localhost/#{user.username}") }
  end

  describe '#can?' do
    it 'forwards call to the given user' do
      expect(user).to receive(:can?).with("a", b: 24)

      presenter.send(:can?, "a", b: 24)
    end
  end

  context 'Gitpod' do
    let(:gitpod_url) { "https://gitpod.io" }
    let(:gitpod_application_enabled) { true }

    before do
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(gitpod_application_enabled)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_url).and_return(gitpod_url)
    end

    context 'Gitpod enabled for application' do
      describe '#preferences_gitpod_path' do
        it { expect(presenter.preferences_gitpod_path).to eq("/-/profile/preferences#user_gitpod_enabled") }
      end

      describe '#profile_enable_gitpod_path' do
        it do
          expect(presenter.profile_enable_gitpod_path).to eq(
            "/-/user_settings/profile?user%5Bgitpod_enabled%5D=true")
        end
      end
    end

    context 'Gitpod disabled for application' do
      let(:gitpod_application_enabled) { false }

      describe '#preferences_gitpod_path' do
        it { expect(presenter.preferences_gitpod_path).to eq(nil) }
      end

      describe '#profile_enable_gitpod_path' do
        it { expect(presenter.profile_enable_gitpod_path).to eq(nil) }
      end
    end
  end

  describe '#saved_replies' do
    let_it_be(:other_user) { create(:user) }
    let_it_be(:saved_reply) { create(:saved_reply, user: user) }

    context 'when user has no permission to read saved replies' do
      let(:current_user) { other_user }

      it { expect(presenter.saved_replies).to eq(::Users::SavedReply.none) }
    end

    context 'when user has permission to read saved replies' do
      it { expect(presenter.saved_replies).to eq([saved_reply]) }
    end
  end
end

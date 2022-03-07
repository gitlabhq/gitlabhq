# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPresenter do
  let_it_be(:user) { create(:user) }

  subject(:presenter) { described_class.new(user) }

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{user.username}") }
  end

  describe '#web_url' do
    it { expect(presenter.web_url).to eq("http://localhost/#{user.username}") }
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
        it { expect(presenter.profile_enable_gitpod_path).to eq("/-/profile?user%5Bgitpod_enabled%5D=true") }
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
end

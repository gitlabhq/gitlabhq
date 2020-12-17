# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Crowd::Authentication do
  let(:provider)           { 'crowd' }
  let(:login)              { generate(:username) }
  let(:password)           { 'password' }
  let(:crowd_auth)         { described_class.new(provider) }
  let(:user_info)          { { user: login } }

  describe 'login' do
    before do
      allow(Gitlab::Auth::OAuth::Provider).to receive(:enabled?).with(provider).and_return(true)
      allow(crowd_auth).to receive(:user_info_from_authentication).and_return(user_info)
    end

    it "finds the user if authentication is successful" do
      create(:omniauth_user, extern_uid: login, username: login, provider: provider)

      expect(crowd_auth.login(login, password)).to be_truthy
    end

    it "is false if the user does not exist" do
      expect(crowd_auth.login(login, password)).to be_falsey
    end

    it "is false if the authentication fails" do
      allow(crowd_auth).to receive(:user_info_from_authentication).and_return(nil)

      expect(crowd_auth.login(login, password)).to be_falsey
    end

    it "fails when crowd is disabled" do
      allow(Gitlab::Auth::OAuth::Provider).to receive(:enabled?).with('crowd').and_return(false)

      expect(crowd_auth.login(login, password)).to be_falsey
    end

    it "fails if no login is supplied" do
      expect(crowd_auth.login('', password)).to be_falsey
    end

    it "fails if no password is supplied" do
      expect(crowd_auth.login(login, '')).to be_falsey
    end
  end
end

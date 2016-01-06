require 'spec_helper'

describe API, api: true do
  include API::Helpers
  include ApiHelpers
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:params) { {} }
  let(:env) { {} }

  def set_env(token_usr, identifier)
    clear_env
    clear_param
    env[API::Helpers::PRIVATE_TOKEN_HEADER] = token_usr.private_token
    env[API::Helpers::SUDO_HEADER] = identifier
  end

  def set_param(token_usr, identifier)
    clear_env
    clear_param
    params[API::Helpers::PRIVATE_TOKEN_PARAM] = token_usr.private_token
    params[API::Helpers::SUDO_PARAM] = identifier
  end

  def clear_env
    env.delete(API::Helpers::PRIVATE_TOKEN_HEADER)
    env.delete(API::Helpers::SUDO_HEADER)
  end

  def clear_param
    params.delete(API::Helpers::PRIVATE_TOKEN_PARAM)
    params.delete(API::Helpers::SUDO_PARAM)
  end

  def error!(message, status)
    raise Exception
  end

  describe ".current_user" do
    it "should return nil for an invalid token" do
      env[API::Helpers::PRIVATE_TOKEN_HEADER] = 'invalid token'
      allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }
      expect(current_user).to be_nil
    end

    it "should return nil for a user without access" do
      env[API::Helpers::PRIVATE_TOKEN_HEADER] = user.private_token
      allow(Gitlab::UserAccess).to receive(:allowed?).and_return(false)
      expect(current_user).to be_nil
    end

    it "should leave user as is when sudo not specified" do
      env[API::Helpers::PRIVATE_TOKEN_HEADER] = user.private_token
      expect(current_user).to eq(user)
      clear_env
      params[API::Helpers::PRIVATE_TOKEN_PARAM] = user.private_token
      expect(current_user).to eq(user)
    end

    it "should change current user to sudo when admin" do
      set_env(admin, user.id)
      expect(current_user).to eq(user)
      set_param(admin, user.id)
      expect(current_user).to eq(user)
      set_env(admin, user.username)
      expect(current_user).to eq(user)
      set_param(admin, user.username)
      expect(current_user).to eq(user)
    end

    it "should throw an error when the current user is not an admin and attempting to sudo" do
      set_env(user, admin.id)
      expect { current_user }.to raise_error(Exception)
      set_param(user, admin.id)
      expect { current_user }.to raise_error(Exception)
      set_env(user, admin.username)
      expect { current_user }.to raise_error(Exception)
      set_param(user, admin.username)
      expect { current_user }.to raise_error(Exception)
    end

    it "should throw an error when the user cannot be found for a given id" do
      id = user.id + admin.id
      expect(user.id).not_to eq(id)
      expect(admin.id).not_to eq(id)
      set_env(admin, id)
      expect { current_user }.to raise_error(Exception)

      set_param(admin, id)
      expect { current_user }.to raise_error(Exception)
    end

    it "should throw an error when the user cannot be found for a given username" do
      username = "#{user.username}#{admin.username}"
      expect(user.username).not_to eq(username)
      expect(admin.username).not_to eq(username)
      set_env(admin, username)
      expect { current_user }.to raise_error(Exception)

      set_param(admin, username)
      expect { current_user }.to raise_error(Exception)
    end

    it "should handle sudo's to oneself" do
      set_env(admin, admin.id)
      expect(current_user).to eq(admin)
      set_param(admin, admin.id)
      expect(current_user).to eq(admin)
      set_env(admin, admin.username)
      expect(current_user).to eq(admin)
      set_param(admin, admin.username)
      expect(current_user).to eq(admin)
    end

    it "should handle multiple sudo's to oneself" do
      set_env(admin, user.id)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
      set_env(admin, user.username)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)

      set_param(admin, user.id)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
      set_param(admin, user.username)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
    end

    it "should handle multiple sudo's to oneself using string ids" do
      set_env(admin, user.id.to_s)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)

      set_param(admin, user.id.to_s)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
    end
  end

  describe '.sudo_identifier' do
    it "should return integers when input is an int" do
      set_env(admin, '123')
      expect(sudo_identifier).to eq(123)
      set_env(admin, '0001234567890')
      expect(sudo_identifier).to eq(1234567890)

      set_param(admin, '123')
      expect(sudo_identifier).to eq(123)
      set_param(admin, '0001234567890')
      expect(sudo_identifier).to eq(1234567890)
    end

    it "should return string when input is an is not an int" do
      set_env(admin, '12.30')
      expect(sudo_identifier).to eq("12.30")
      set_env(admin, 'hello')
      expect(sudo_identifier).to eq('hello')
      set_env(admin, ' 123')
      expect(sudo_identifier).to eq(' 123')

      set_param(admin, '12.30')
      expect(sudo_identifier).to eq("12.30")
      set_param(admin, 'hello')
      expect(sudo_identifier).to eq('hello')
      set_param(admin, ' 123')
      expect(sudo_identifier).to eq(' 123')
    end
  end
end

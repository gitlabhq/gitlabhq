require 'spec_helper'

describe API, api: true do
  include API::APIHelpers
  include ApiHelpers
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:params) { {} }
  let(:env) { {} }

  def set_env(token_usr, identifier)
    clear_env
    clear_param
    env[API::APIHelpers::PRIVATE_TOKEN_HEADER] = token_usr.private_token
    env[API::APIHelpers::SUDO_HEADER] = identifier
  end

  def set_param(token_usr, identifier)
    clear_env
    clear_param
    params[API::APIHelpers::PRIVATE_TOKEN_PARAM] = token_usr.private_token
    params[API::APIHelpers::SUDO_PARAM] = identifier
  end

  def clear_env
    env.delete(API::APIHelpers::PRIVATE_TOKEN_HEADER)
    env.delete(API::APIHelpers::SUDO_HEADER)
  end

  def clear_param
    params.delete(API::APIHelpers::PRIVATE_TOKEN_PARAM)
    params.delete(API::APIHelpers::SUDO_PARAM)
  end

  def error!(message, status)
    raise Exception
  end

  describe ".current_user" do
    it "should return nil for an invalid token" do
      env[API::APIHelpers::PRIVATE_TOKEN_HEADER] = 'invalid token'
      current_user.should be_nil
    end

    it "should return nil for a user without access" do
      env[API::APIHelpers::PRIVATE_TOKEN_HEADER] = user.private_token
      Gitlab::UserAccess.stub(allowed?: false)
      current_user.should be_nil
    end

    it "should leave user as is when sudo not specified" do
      env[API::APIHelpers::PRIVATE_TOKEN_HEADER] = user.private_token
      current_user.should == user
      clear_env
      params[API::APIHelpers::PRIVATE_TOKEN_PARAM] = user.private_token
      current_user.should == user
    end

    it "should change current user to sudo when admin" do
      set_env(admin, user.id)
      current_user.should == user
      set_param(admin, user.id)
      current_user.should == user
      set_env(admin, user.username)
      current_user.should == user
      set_param(admin, user.username)
      current_user.should == user
    end

    it "should throw an error when the current user is not an admin and attempting to sudo" do
      set_env(user, admin.id)
      expect { current_user }.to raise_error
      set_param(user, admin.id)
      expect { current_user }.to raise_error
      set_env(user, admin.username)
      expect { current_user }.to raise_error
      set_param(user, admin.username)
      expect { current_user }.to raise_error
    end

    it "should throw an error when the user cannot be found for a given id" do
      id = user.id + admin.id
      user.id.should_not == id
      admin.id.should_not == id
      set_env(admin, id)
      expect { current_user }.to raise_error

      set_param(admin, id)
      expect { current_user }.to raise_error
    end

    it "should throw an error when the user cannot be found for a given username" do
      username = "#{user.username}#{admin.username}"
      user.username.should_not == username
      admin.username.should_not == username
      set_env(admin, username)
      expect { current_user }.to raise_error

      set_param(admin, username)
      expect { current_user }.to raise_error
    end

    it "should handle sudo's to oneself" do
      set_env(admin, admin.id)
      current_user.should == admin
      set_param(admin, admin.id)
      current_user.should == admin
      set_env(admin, admin.username)
      current_user.should == admin
      set_param(admin, admin.username)
      current_user.should == admin
    end

    it "should handle multiple sudo's to oneself" do
      set_env(admin, user.id)
      current_user.should == user
      current_user.should == user
      set_env(admin, user.username)
      current_user.should == user
      current_user.should == user

      set_param(admin, user.id)
      current_user.should == user
      current_user.should == user
      set_param(admin, user.username)
      current_user.should == user
      current_user.should == user
    end

    it "should handle multiple sudo's to oneself using string ids" do
      set_env(admin, user.id.to_s)
      current_user.should == user
      current_user.should == user

      set_param(admin, user.id.to_s)
      current_user.should == user
      current_user.should == user
    end
  end

  describe '.sudo_identifier' do
    it "should return integers when input is an int" do
      set_env(admin, '123')
      sudo_identifier.should == 123
      set_env(admin, '0001234567890')
      sudo_identifier.should == 1234567890

      set_param(admin, '123')
      sudo_identifier.should == 123
      set_param(admin, '0001234567890')
      sudo_identifier.should == 1234567890
    end

    it "should return string when input is an is not an int" do
      set_env(admin, '12.30')
      sudo_identifier.should == "12.30"
      set_env(admin, 'hello')
      sudo_identifier.should == 'hello'
      set_env(admin, ' 123')
      sudo_identifier.should == ' 123'

      set_param(admin, '12.30')
      sudo_identifier.should == "12.30"
      set_param(admin, 'hello')
      sudo_identifier.should == 'hello'
      set_param(admin, ' 123')
      sudo_identifier.should == ' 123'
    end
  end
end

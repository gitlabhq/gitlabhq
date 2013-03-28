require 'spec_helper'

describe Gitlab::API do
  include Gitlab::APIHelpers
  include ApiHelpers
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:params) { {} }
  let(:env) { {} }

  def set_env(token_usr, identifier)
    clear_env
    clear_param
    env[Gitlab::APIHelpers::PRIVATE_TOKEN_HEADER] = token_usr.private_token
    env[Gitlab::APIHelpers::SUDO_HEADER] = identifier
  end


  def set_param(token_usr, identifier)
    clear_env
    clear_param
    params[Gitlab::APIHelpers::PRIVATE_TOKEN_PARAM] = token_usr.private_token
    params[Gitlab::APIHelpers::SUDO_PARAM] = identifier
  end


  def clear_env
    env.delete(Gitlab::APIHelpers::PRIVATE_TOKEN_HEADER)
    env.delete(Gitlab::APIHelpers::SUDO_HEADER)
  end

  def clear_param
    params.delete(Gitlab::APIHelpers::PRIVATE_TOKEN_PARAM)
    params.delete(Gitlab::APIHelpers::SUDO_PARAM)
  end

  def error!(message, status)
    raise Exception
  end

  describe "current_user" do
    it "should leave user as is when sudo not specified" do
      env[Gitlab::APIHelpers::PRIVATE_TOKEN_HEADER] = user.private_token
      current_user.should == user
      clear_env
      params[Gitlab::APIHelpers::PRIVATE_TOKEN_PARAM] = user.private_token
      current_user.should == user
    end

    it "should change current user to sudo when admin" do
      set_env(admin,user.id)
      current_user.should == user
      set_param(admin,user.id)
      current_user.should == user
      set_env(admin,user.username)
      current_user.should == user
      set_param(admin,user.username)
      current_user.should == user
    end

    it "should throw an error when the current user is not an admin and attempting to sudo" do
      set_env(user,admin.id)
      expect { current_user }.to raise_error
      set_param(user,admin.id)
      expect { current_user }.to raise_error
      set_env(user,admin.username)
      expect { current_user }.to raise_error
      set_param(user,admin.username)
      expect { current_user }.to raise_error
    end
    it "should throw an error when the user cannot be found for a given id" do
      id = user.id + admin.id
      user.id.should_not == id
      admin.id.should_not == id
      set_env(admin,id)
      expect { current_user }.to raise_error

      set_param(admin,id)
      expect { current_user }.to raise_error
    end
    it "should throw an error when the user cannot be found for a given username" do
      username = "#{user.username}#{admin.username}"
      user.username.should_not == username
      admin.username.should_not == username
      set_env(admin,username)
      expect { current_user }.to raise_error

      set_param(admin,username)
      expect { current_user }.to raise_error
    end
    it "should handle sudo's to oneself" do
      set_env(admin,admin.id)
      current_user.should == admin
      set_param(admin,admin.id)
      current_user.should == admin
      set_env(admin,admin.username)
      current_user.should == admin
      set_param(admin,admin.username)
      current_user.should == admin
    end
  end
end
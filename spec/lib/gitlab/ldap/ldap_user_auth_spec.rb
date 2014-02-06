require 'spec_helper'

describe Gitlab::LDAP do
  let(:gl_auth) { Gitlab::LDAP::User }

  before do
    Gitlab.config.stub(omniauth: {})

    @info = double(
      uid: '12djsak321',
      name: 'John',
      email: 'john@mail.com'
    )
  end

  describe :find_for_ldap_auth do
    before do
      @auth = double(
        uid: '12djsak321',
        info: @info,
        provider: 'ldap'
      )
    end

    it "should update credentials by email if missing uid" do
      user = double('User')
      User.stub find_by_extern_uid_and_provider: nil
      User.stub(:find_by).with(hash_including(email: anything())) { user }
      user.should_receive :update_attributes
      gl_auth.find_or_create(@auth)
    end

    it "should update credentials by username if missing uid and Gitlab.config.ldap.allow_username_or_email_login is true" do
      user = double('User')
      value = Gitlab.config.ldap.allow_username_or_email_login
      Gitlab.config.ldap['allow_username_or_email_login'] = true
      User.stub find_by_extern_uid_and_provider: nil
      User.stub(:find_by).with(hash_including(email: anything())) { nil }
      User.stub(:find_by).with(hash_including(username: anything())) { user }
      user.should_receive :update_attributes
      gl_auth.find_or_create(@auth)
      Gitlab.config.ldap['allow_username_or_email_login'] = value
    end

    it "should not update credentials by username if missing uid and Gitlab.config.ldap.allow_username_or_email_login is false" do
      user = double('User')
      value = Gitlab.config.ldap.allow_username_or_email_login
      Gitlab.config.ldap['allow_username_or_email_login'] = false
      User.stub find_by_extern_uid_and_provider: nil
      User.stub(:find_by).with(hash_including(email: anything())) { nil }
      User.stub(:find_by).with(hash_including(username: anything())) { user }
      user.should_not_receive :update_attributes
      gl_auth.find_or_create(@auth)
      Gitlab.config.ldap['allow_username_or_email_login'] = value
    end
  end
end

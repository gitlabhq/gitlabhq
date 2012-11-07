require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { Gitlab::Auth.new }

  before do
    Gitlab.config.stub(omniauth: {})

    @info = mock(
      uid: '12djsak321',
      name: 'John',
      email: 'john@mail.com'
    )
  end

  describe :find_or_new_for_omniauth do
    before do
      @auth = mock(
        info: @info,
        provider: 'twitter',
        uid: '12djsak321',
      )
    end

    it "should find user"do
      User.should_receive :find_by_provider_and_extern_uid
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should not create user"do
      User.stub find_by_provider_and_extern_uid: nil
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should create user if single_sing_on"do
      Gitlab.config.omniauth['allow_single_sign_on'] = true
      User.stub find_by_provider_and_extern_uid: nil
      gl_auth.find_or_new_for_omniauth(@auth)
    end
  end

end

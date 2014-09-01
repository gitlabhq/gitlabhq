require 'spec_helper'

describe Gitlab::OAuth::User do
  let(:gl_auth) { Gitlab::OAuth::User }
  let(:info) do
    double(
      uid: 'my-uid',
      nickname: 'john',
      name: 'John',
      email: 'john@mail.com'
    )
  end

  before do
    Gitlab.config.stub(omniauth: {})
  end

  describe :find do
    let!(:existing_user) { create(:user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      auth = double(info: double(name: 'John'), uid: 'my-uid', provider: 'my-provider')
      assert gl_auth.find(auth)
    end

    it "finds an existing user based on nested uid and provider" do
      auth = double(info: info, provider: 'my-provider')
      assert gl_auth.find(auth)
    end
  end

  describe :create do
    it "should create user from LDAP" do
      auth = double(info: info, provider: 'ldap')
      user = gl_auth.create(auth)

      user.should be_valid
      user.extern_uid.should == info.uid
      user.provider.should == 'ldap'
    end

    it "should create user from Omniauth" do
      auth = double(info: info, provider: 'twitter')
      user = gl_auth.create(auth)

      user.should be_valid
      user.extern_uid.should == info.uid
      user.provider.should == 'twitter'
    end

    it "should apply defaults to user" do
      auth = double(info: info, provider: 'ldap')
      user = gl_auth.create(auth)

      user.should be_valid
      user.projects_limit.should == Gitlab.config.gitlab.default_projects_limit
      user.can_create_group.should == Gitlab.config.gitlab.default_can_create_group
    end

    it "Set a temp email address if not provided (like twitter does)" do
      info = double(
        uid: 'my-uid',
        nickname: 'john',
        name: 'John'
      )
      auth = double(info: info, provider: 'my-provider')

      user = gl_auth.create(auth)
      expect(user.email).to_not be_empty
    end

    it 'generates a username if non provided (google)' do
      info = double(
        uid: 'my-uid',
        name: 'John',
        email: 'john@example.com'
      )
      auth = double(info: info, provider: 'my-provider')

      user = gl_auth.create(auth)
      expect(user.username).to eql 'john'
    end
  end
end

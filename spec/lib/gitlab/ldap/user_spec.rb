require 'spec_helper'

describe Gitlab::LDAP::User do
  let(:gl_auth) { Gitlab::LDAP::User }
  let(:info) do
    double(
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    )
  end
  before { Gitlab.config.stub(omniauth: {}) }

  describe :find_or_create do
    let(:auth) do
      double(info: info, provider: 'ldap', uid: 'my-uid')
    end

    it "finds the user if already existing" do
      existing_user = create(:user, extern_uid: 'my-uid', provider: 'ldap')

      expect{ gl_auth.find_or_create(auth) }.to_not change{ User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:user, email: 'john@example.com')
      expect{ gl_auth.find_or_create(auth) }.to_not change{ User.count }

      existing_user.reload
      expect(existing_user.extern_uid).to eql 'my-uid'
      expect(existing_user.provider).to eql 'ldap'
    end

    it "creates a new user if not found" do
      expect{ gl_auth.find_or_create(auth) }.to change{ User.count }.by(1)
    end
  end
end

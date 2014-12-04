require 'spec_helper'

describe Gitlab::LDAP::User do
  let(:gl_user) { Gitlab::LDAP::User.new(auth_hash) }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end
  let(:auth_hash) do
    double(uid: 'my-uid', provider: 'ldapmain', info: double(info))
  end

  describe :find_or_create do
    it "finds the user if already existing" do
      existing_user = create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')

      expect{ gl_user.save }.to_not change{ User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: "twitter")
      expect{ gl_user.save }.to_not change{ User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
    end

    it "creates a new user if not found" do
      expect{ gl_user.save }.to change{ User.count }.by(1)
    end
  end
end

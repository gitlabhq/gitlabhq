require 'spec_helper'

describe PersonalAccessToken do
  subject { described_class }

  describe '.build' do
    let(:personal_access_token) { build(:personal_access_token) }
    let(:invalid_personal_access_token) { build(:personal_access_token, :invalid) }

    it 'is a valid personal access token' do
      expect(personal_access_token).to be_valid
    end

    it 'ensures that the token is generated' do
      invalid_personal_access_token.save!

      expect(invalid_personal_access_token).to be_valid
      expect(invalid_personal_access_token.token).not_to be_nil
    end
  end

  describe ".active?" do
    let(:active_personal_access_token) { build(:personal_access_token) }
    let(:revoked_personal_access_token) { build(:personal_access_token, :revoked) }
    let(:expired_personal_access_token) { build(:personal_access_token, :expired) }

    it "returns false if the personal_access_token is revoked" do
      expect(revoked_personal_access_token).not_to be_active
    end

    it "returns false if the personal_access_token is expired" do
      expect(expired_personal_access_token).not_to be_active
    end

    it "returns true if the personal_access_token is not revoked and not expired" do
      expect(active_personal_access_token).to be_active
    end
  end

  describe 'revoke!' do
    let(:active_personal_access_token) { create(:personal_access_token) }

    it 'revokes the token' do
      active_personal_access_token.revoke!

      expect(active_personal_access_token).to be_revoked
    end
  end

  describe 'Redis storage' do
    let(:user_id) { 123 }
    let(:token) { 'abc000foo' }

    before do
      subject.redis_store!(user_id, token)
    end

    it 'returns stored data' do
      expect(subject.redis_getdel(user_id)).to eq(token)
    end

    context 'after deletion' do
      before do
        expect(subject.redis_getdel(user_id)).to eq(token)
      end

      it 'token is removed' do
        expect(subject.redis_getdel(user_id)).to be_nil
      end
    end
  end

  context "validations" do
    let(:personal_access_token) { build(:personal_access_token) }

    it "requires at least one scope" do
      personal_access_token.scopes = []

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can't be blank"
    end

    it "allows creating a token with API scopes" do
      personal_access_token.scopes = [:api, :read_user]

      expect(personal_access_token).to be_valid
    end

    context 'when registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it "rejects creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
      end

      it "allows revoking a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        personal_access_token.revoke!

        expect(personal_access_token).to be_revoked
      end
    end

    context 'when registry is enabled' do
      before do
        stub_container_registry_config(enabled: true)
      end

      it "allows creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).to be_valid
      end
    end

    it "rejects creating a token with unavailable scopes" do
      personal_access_token.scopes = [:openid, :api]

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
    end
  end
end

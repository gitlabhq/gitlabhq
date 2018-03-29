require 'spec_helper'

describe DeployToken do
  let(:deploy_token) { create(:deploy_token) }

  it { is_expected.to belong_to :project }

  describe 'validations' do
    context 'with no scopes defined' do
      it 'should not be valid' do
        deploy_token.scopes = []

        expect(deploy_token).not_to be_valid
        expect(deploy_token.errors[:scopes].first).to eq("can't be blank")
      end
    end
  end

  describe '#ensure_token' do
    it 'should ensure a token' do
      deploy_token.token = nil
      deploy_token.save

      expect(deploy_token.token).not_to be_empty
    end
  end

  describe '#revoke!' do
    it 'should update revoke attribute' do
      deploy_token.revoke!
      expect(deploy_token.revoked?).to be_truthy
    end
  end

  describe "#active?" do
    context "when it has been revoked" do
      it 'should return false' do
        deploy_token.revoke!
        expect(deploy_token.active?).to be_falsy
      end
    end

    context "when it hasn't been revoked" do
      it 'should return true' do
        expect(deploy_token.active?).to be_truthy
      end
    end
  end

  describe '#username' do
    it 'returns Ghost username' do
      ghost = User.ghost
      expect(deploy_token.username).to eq(ghost.username)
    end
  end
end

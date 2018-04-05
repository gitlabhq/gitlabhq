require 'spec_helper'

describe DeployToken do
  subject(:deploy_token) { create(:deploy_token) }

  it { is_expected.to have_many :project_deploy_tokens }
  it { is_expected.to have_many(:projects).through(:project_deploy_tokens) }

  describe '#ensure_token' do
    it 'should ensure a token' do
      deploy_token.token = nil
      deploy_token.save

      expect(deploy_token.token).not_to be_empty
    end
  end

  describe '#ensure_at_least_one_scope' do
    context 'with at least one scope' do
      it 'should be valid' do
        is_expected.to be_valid
      end
    end

    context 'with no scopes' do
      it 'should be invalid' do
        deploy_token = build(:deploy_token, read_repository: false, read_registry: false)

        expect(deploy_token).not_to be_valid
        expect(deploy_token.errors[:base].first).to eq("Scopes can't be blank")
      end
    end
  end

  describe '#scopes' do
    context 'with all the scopes' do
      it 'should return scopes assigned to DeployToken' do
        expect(deploy_token.scopes).to eq([:read_repository, :read_registry])
      end
    end

    context 'with only one scope' do
      it 'should return scopes assigned to DeployToken' do
        deploy_token = create(:deploy_token, read_registry: false)
        expect(deploy_token.scopes).to eq([:read_repository])
      end
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
      expect(deploy_token.username).to eq("gitlab+deploy-token-#{deploy_token.id}")
    end
  end
end

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
    it 'returns a harcoded username' do
      expect(deploy_token.username).to eq("gitlab+deploy-token-#{deploy_token.id}")
    end
  end

  describe '#has_access_to?' do
    let(:project) { create(:project) }

    subject { deploy_token.has_access_to?(project) }

    context 'when deploy token is active and related to project' do
      let(:deploy_token) { create(:deploy_token, projects: [project]) }

      it { is_expected.to be_truthy }
    end

    context 'when deploy token is active but not related to project' do
      let(:deploy_token) { create(:deploy_token) }

      it { is_expected.to be_falsy }
    end

    context 'when deploy token is revoked and related to project' do
      let(:deploy_token) { create(:deploy_token, :revoked, projects: [project]) }

      it { is_expected.to be_falsy }
    end

    context 'when deploy token is revoked and not related to the project' do
      let(:deploy_token) { create(:deploy_token, :revoked) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#expires_at' do
    context 'when using Forever.date' do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'should return nil' do
        expect(deploy_token.expires_at).to be_nil
      end
    end

    context 'when using a personalized date' do
      let(:expires_at) { Date.today + 5.months }
      let(:deploy_token) { create(:deploy_token, expires_at: expires_at) }

      it 'should return the personalized date' do
        expect(deploy_token.expires_at).to eq(expires_at)
      end
    end
  end

  describe '#expires_at=' do
    context 'when passing nil' do
      let(:deploy_token) { create(:deploy_token, expires_at: nil) }

      it 'should assign Forever.date' do
        expect(deploy_token.read_attribute(:expires_at)).to eq(Forever.date)
      end
    end

    context 'when passign a value' do
      let(:expires_at) { Date.today + 5.months }
      let(:deploy_token) { create(:deploy_token, expires_at: expires_at) }

      it 'should respect the value' do
        expect(deploy_token.read_attribute(:expires_at)).to eq(expires_at)
      end
    end
  end

  describe '.gitlab_deploy_token' do
    let(:project) { create(:project ) }

    subject { project.deploy_tokens.gitlab_deploy_token }

    context 'with a gitlab deploy token associated' do
      it 'should return the gitlab deploy token' do
        deploy_token = create(:deploy_token, :gitlab_deploy_token, projects: [project])
        is_expected.to eq(deploy_token)
      end
    end

    context 'with no gitlab deploy token associated' do
      it 'should return nil' do
        is_expected.to be_nil
      end
    end
  end
end

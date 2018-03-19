require 'spec_helper'

describe DeployToken do
  it { is_expected.to belong_to :project }

  describe 'validations' do
    let(:project_deploy_token) { build(:deploy_token) }

    context 'with no scopes defined' do
      it 'should not be valid' do
        project_deploy_token.scopes = []

        expect(project_deploy_token).not_to be_valid
        expect(project_deploy_token.errors[:scopes].first).to eq("can't be blank")
      end
    end
  end

  describe '#ensure_token' do
    let(:project_deploy_token) { build(:deploy_token) }

    it 'should ensure a token' do
      project_deploy_token.token = nil
      project_deploy_token.save

      expect(project_deploy_token.token).not_to be_empty
    end
  end

  describe '#revoke!' do
    subject { create(:deploy_token) }

    it 'should update revoke attribute' do
      subject.revoke!
      expect(subject.revoked?).to be_truthy
    end
  end
end

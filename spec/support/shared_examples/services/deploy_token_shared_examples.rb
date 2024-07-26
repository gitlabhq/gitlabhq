# frozen_string_literal: true

RSpec.shared_examples 'a deploy token creation service' do
  let(:user) { create(:user) }
  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    context 'when the deploy token is valid' do
      it 'creates a new DeployToken' do
        expect { subject }.to change { DeployToken.count }.by(1)
      end

      it 'creates a new ProjectDeployToken' do
        expect { subject }.to change { deploy_token_class.count }.by(1)
      end

      it 'returns a DeployToken' do
        expect(subject[:deploy_token]).to be_an_instance_of DeployToken
      end

      it 'sets the creator_id as the id of the current_user' do
        expect(subject[:deploy_token].read_attribute(:creator_id)).to eq(user.id)
      end

      it 'sets the sharding key' do
        sharding_key = "#{entity.class.name.downcase}_id"

        expect(subject[:deploy_token].read_attribute(sharding_key)).to eq(entity.id)
      end
    end

    context 'when expires at date is not passed' do
      let(:deploy_token_params) { attributes_for(:deploy_token, expires_at: '') }

      it 'sets Forever.date' do
        expect(subject[:deploy_token].read_attribute(:expires_at)).to eq(Forever.date)
      end
    end

    context 'when username is empty string' do
      let(:deploy_token_params) { attributes_for(:deploy_token, username: '') }

      it 'converts it to nil' do
        expect(subject[:deploy_token].read_attribute(:username)).to be_nil
      end
    end

    context 'when username is provided' do
      let(:deploy_token_params) { attributes_for(:deploy_token, username: 'deployer') }

      it 'keeps the provided username' do
        expect(subject[:deploy_token].read_attribute(:username)).to eq('deployer')
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) do
        attributes_for(:deploy_token, read_repository: false, read_registry: false, write_registry: false)
      end

      it 'does not create a new DeployToken' do
        expect { subject }.not_to change { DeployToken.count }
      end

      it 'does not create a new ProjectDeployToken' do
        expect { subject }.not_to change { deploy_token_class.count }
      end
    end
  end
end

RSpec.shared_examples 'a deploy token deletion service' do
  let(:user) { create(:user) }
  let(:deploy_token_params) { { token_id: deploy_token.id } }

  describe '#execute' do
    subject { described_class.new(entity, user, deploy_token_params).execute }

    it "destroys a token record and it's associated DeployToken" do
      expect { subject }.to change { deploy_token_class.count }.by(-1)
        .and change { DeployToken.count }.by(-1)
    end

    context 'with invalid token id' do
      let(:deploy_token_params) { { token_id: 9999 } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

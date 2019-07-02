# frozen_string_literal: true

require 'spec_helper'

describe DeployTokens::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(project, user, deploy_token_params).execute }

    context 'when the deploy token is valid' do
      it 'creates a new DeployToken' do
        expect { subject }.to change { DeployToken.count }.by(1)
      end

      it 'creates a new ProjectDeployToken' do
        expect { subject }.to change { ProjectDeployToken.count }.by(1)
      end

      it 'returns a DeployToken' do
        expect(subject).to be_an_instance_of DeployToken
      end
    end

    context 'when expires at date is not passed' do
      let(:deploy_token_params) { attributes_for(:deploy_token, expires_at: '') }

      it 'sets Forever.date' do
        expect(subject.read_attribute(:expires_at)).to eq(Forever.date)
      end
    end

    context 'when username is empty string' do
      let(:deploy_token_params) { attributes_for(:deploy_token, username: '') }

      it 'converts it to nil' do
        expect(subject.read_attribute(:username)).to be_nil
      end
    end

    context 'when username is provided' do
      let(:deploy_token_params) { attributes_for(:deploy_token, username: 'deployer') }

      it 'keeps the provided username' do
        expect(subject.read_attribute(:username)).to eq('deployer')
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) { attributes_for(:deploy_token, read_repository: false, read_registry: false) }

      it 'does not create a new DeployToken' do
        expect { subject }.not_to change { DeployToken.count }
      end

      it 'does not create a new ProjectDeployToken' do
        expect { subject }.not_to change { ProjectDeployToken.count }
      end
    end
  end
end

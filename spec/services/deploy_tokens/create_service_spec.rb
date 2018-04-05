require 'spec_helper'

describe DeployTokens::CreateService, :clean_gitlab_redis_shared_state do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:deploy_token_params) { attributes_for(:deploy_token) }

  describe '#execute' do
    subject { described_class.new(project, user, deploy_token_params).execute }

    context 'when the deploy token is valid' do
      it 'should create a new DeployToken' do
        expect { subject }.to change { DeployToken.count }.by(1)
      end

      it 'should create a new ProjectDeployToken' do
        expect { subject }.to change { ProjectDeployToken.count }.by(1)
      end

      it 'returns a DeployToken' do
        expect(subject).to be_an_instance_of DeployToken
      end

      it 'should store the token on redis' do
        redis_key = DeployToken.redis_shared_state_key(user.id)
        subject

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).not_to be_nil
      end

      it 'should not store deploy token attributes on redis' do
        redis_key = DeployToken.redis_shared_state_key(user.id) + ":attributes"
        subject

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to be_nil
      end
    end

    context 'when the deploy token is invalid' do
      let(:deploy_token_params) { attributes_for(:deploy_token, read_repository: false, read_registry: false) }

      it 'should not create a new DeployToken' do
        expect { subject }.not_to change { DeployToken.count }
      end

      it 'should not create a new ProjectDeployToken' do
        expect { subject }.not_to change { ProjectDeployToken.count }
      end

      it 'should not store the token on redis' do
        redis_key = DeployToken.redis_shared_state_key(user.id)
        subject

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to be_nil
      end

      it 'should store deploy token attributes on redis' do
        redis_key = DeployToken.redis_shared_state_key(user.id) + ":attributes"
        subject

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).not_to be_nil
      end
    end
  end
end

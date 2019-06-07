# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::LfsToken, :clean_gitlab_redis_shared_state do
  describe '#token' do
    shared_examples 'a valid LFS token' do
      it 'returns a computed token' do
        token = lfs_token.token

        expect(token).not_to be_nil
        expect(token).to be_a String
        expect(described_class.new(actor).token_valid?(token)).to be_truthy
      end
    end

    context 'when the actor is a user' do
      let(:actor) { create(:user, username: 'test_user_lfs_1') }
      let(:lfs_token) { described_class.new(actor) }

      it_behaves_like 'a valid LFS token'

      it 'returns the correct username' do
        expect(lfs_token.actor_name).to eq(actor.username)
      end

      it 'returns the correct token type' do
        expect(lfs_token.type).to eq(:lfs_token)
      end
    end

    context 'when the actor is a key' do
      let(:user) { create(:user, username: 'test_user_lfs_2') }
      let(:actor) { create(:key, user: user) }
      let(:lfs_token) { described_class.new(actor) }

      it_behaves_like 'a valid LFS token'

      it 'returns the correct username' do
        expect(lfs_token.actor_name).to eq(user.username)
      end

      it 'returns the correct token type' do
        expect(lfs_token.type).to eq(:lfs_token)
      end
    end

    context 'when the actor is a deploy key' do
      let(:actor_id) { 1 }
      let(:actor) { create(:deploy_key) }
      let(:project) { create(:project) }
      let(:lfs_token) { described_class.new(actor) }

      before do
        allow(actor).to receive(:id).and_return(actor_id)
      end

      it_behaves_like 'a valid LFS token'

      it 'returns the correct username' do
        expect(lfs_token.actor_name).to eq("lfs+deploy-key-#{actor_id}")
      end

      it 'returns the correct token type' do
        expect(lfs_token.type).to eq(:lfs_deploy_token)
      end
    end

    context 'when the actor is invalid' do
      it 'raises an exception' do
        expect { described_class.new('invalid') }.to raise_error('Bad Actor')
      end
    end
  end

  describe '#token_valid?' do
    let(:actor) { create(:user, username: 'test_user_lfs_1') }
    let(:lfs_token) { described_class.new(actor) }

    context 'where the token is invalid' do
      context "because it's junk" do
        it 'returns false' do
          expect(lfs_token.token_valid?('junk')).to be_falsey
        end
      end

      context "because it's been fiddled with" do
        it 'returns false' do
          fiddled_token = lfs_token.token.tap { |token| token[0] = 'E' }
          expect(lfs_token.token_valid?(fiddled_token)).to be_falsey
        end
      end

      context "because it was generated with a different secret" do
        it 'returns false' do
          different_actor = create(:user, username: 'test_user_lfs_2')
          different_secret_token = described_class.new(different_actor).token
          expect(lfs_token.token_valid?(different_secret_token)).to be_falsey
        end
      end

      context "because it's expired" do
        it 'returns false' do
          expired_token = lfs_token.token
          # Needs to be at least 1860 seconds, because the default expiry is
          # 1800 seconds with an additional 60 second leeway.
          Timecop.freeze(Time.now + 1865) do
            expect(lfs_token.token_valid?(expired_token)).to be_falsey
          end
        end
      end

      context 'where the token is valid' do
        it 'returns true' do
          expect(lfs_token.token_valid?(lfs_token.token)).to be_truthy
        end
      end
    end
  end

  describe '#deploy_key_pushable?' do
    let(:lfs_token) { described_class.new(actor) }

    context 'when actor is not a DeployKey' do
      let(:actor) { create(:user) }
      let(:project) { create(:project) }

      it 'returns false' do
        expect(lfs_token.deploy_key_pushable?(project)).to be_falsey
      end
    end

    context 'when actor is a DeployKey' do
      let(:deploy_keys_project) { create(:deploy_keys_project, can_push: can_push) }
      let(:project) { deploy_keys_project.project }
      let(:actor) { deploy_keys_project.deploy_key }

      context 'but the DeployKey cannot push to the project' do
        let(:can_push) { false }

        it 'returns false' do
          expect(lfs_token.deploy_key_pushable?(project)).to be_falsey
        end
      end

      context 'and the DeployKey can push to the project' do
        let(:can_push) { true }

        it 'returns true' do
          expect(lfs_token.deploy_key_pushable?(project)).to be_truthy
        end
      end
    end
  end

  describe '#type' do
    let(:lfs_token) { described_class.new(actor) }

    context 'when actor is not a User' do
      let(:actor) { create(:deploy_key) }

      it 'returns false' do
        expect(lfs_token.type).to eq(:lfs_deploy_token)
      end
    end

    context 'when actor is a User' do
      let(:actor) { create(:user) }

      it 'returns false' do
        expect(lfs_token.type).to eq(:lfs_token)
      end
    end
  end

  describe '#authentication_payload' do
    it 'returns a Hash designed for gitlab-shell' do
      actor = create(:user)
      lfs_token = described_class.new(actor)
      repo_http_path = 'http://localhost/user/repo.git'
      authentication_payload = lfs_token.authentication_payload(repo_http_path)

      expect(authentication_payload[:username]).to eq(actor.username)
      expect(authentication_payload[:repository_http_path]).to eq(repo_http_path)
      expect(authentication_payload[:lfs_token]).to be_a String
      expect(authentication_payload[:expires_in]).to eq(described_class::DEFAULT_EXPIRE_TIME)
    end
  end
end

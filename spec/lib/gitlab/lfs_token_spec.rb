# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LfsToken, :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:user)       { create(:user) }
  let_it_be(:project)    { create(:project) }
  let_it_be(:deploy_key) { create(:deploy_key) }

  let(:actor)     { user }
  let(:lfs_token) { described_class.new(actor, project) }

  describe '#token' do
    shared_examples 'a valid LFS token' do
      it 'returns a computed token' do
        token = lfs_token.token

        expect(token).not_to be_nil
        expect(token).to be_a String
        expect(described_class.new(actor, project).token_valid?(token)).to be true
      end
    end

    context 'when the actor is a user' do
      it_behaves_like 'a valid LFS token'

      it 'returns the correct username' do
        expect(lfs_token.actor_name).to eq(actor.username)
      end

      it 'returns the correct token type' do
        expect(lfs_token.type).to eq(:lfs_token)
      end

      it 'returns a container_gid' do
        expect(lfs_token.container_gid).to eq(Gitlab::GlobalId.build(project).to_s)
      end
    end

    context 'when the actor is a key' do
      let_it_be(:actor) { create(:key, user: user) }

      it_behaves_like 'a valid LFS token'

      it 'returns the correct username' do
        expect(lfs_token.actor_name).to eq(user.username)
      end

      it 'returns the correct token type' do
        expect(lfs_token.type).to eq(:lfs_token)
      end

      it 'returns a container_gid' do
        expect(lfs_token.container_gid).to eq(Gitlab::GlobalId.build(project).to_s)
      end
    end

    context 'when the actor is a deploy key' do
      let(:actor) { deploy_key }
      let(:actor_id) { 1 }

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

      it 'returns a container_gid' do
        expect(lfs_token.container_gid).to eq(Gitlab::GlobalId.build(project).to_s)
      end
    end

    context 'when the actor is invalid' do
      it 'raises an exception' do
        expect { described_class.new('invalid', project) }.to raise_error('Bad Actor')
      end
    end

    context 'when container is missing' do
      let(:project) { nil }

      it_behaves_like 'a valid LFS token'

      it 'returns an empty container_gid' do
        expect(lfs_token.container_gid).to eq(nil)
      end
    end
  end

  describe '#token_valid?' do
    context 'where the token is invalid' do
      context "because it's junk" do
        it 'returns false' do
          expect(lfs_token.token_valid?('junk')).to be false
        end
      end

      context "because it's been fiddled with" do
        it 'returns false' do
          fiddled_token = lfs_token.token.tap { |token| token[0] = 'E' }

          expect(lfs_token.token_valid?(fiddled_token)).to be false
        end
      end

      context 'because it was generated with a different secret' do
        it 'returns false' do
          different_actor = create(:user, username: 'test_user_lfs_2')
          different_secret_token = described_class.new(different_actor, project).token

          expect(lfs_token.token_valid?(different_secret_token)).to be false
        end
      end

      context "because it's expired" do
        it 'returns false' do
          expired_token = lfs_token.token

          # Needs to be at least LfsToken::DEFAULT_EXPIRE_TIME + 60 seconds
          # in order to check whether it is valid 1 minute after it has expired
          travel_to(Time.now + described_class::DEFAULT_EXPIRE_TIME + 60) do
            expect(lfs_token.token_valid?(expired_token)).to be false
          end
        end
      end

      context 'because it was generated for a different project' do
        it 'returns false' do
          different_secret_token = described_class.new(actor, create(:project)).token

          expect(lfs_token.token_valid?(different_secret_token)).to be false
        end
      end

      context 'where the token is valid' do
        it 'returns true' do
          expect(lfs_token.token_valid?(lfs_token.token)).to be true
        end
      end

      context 'when the actor is a regular user' do
        context 'when the user is blocked' do
          let(:actor) { create(:user, :blocked) }

          it 'returns false' do
            expect(lfs_token.token_valid?(lfs_token.token)).to be false
          end
        end

        context 'when the user password is expired' do
          let(:actor) { create(:user, password_expires_at: 1.minute.ago) }

          it 'returns false' do
            expect(lfs_token.token_valid?(lfs_token.token)).to be false
          end
        end
      end

      context 'when the actor is an ldap user' do
        let(:actor) { create(:omniauth_user, provider: 'ldap') }

        context 'when the user is blocked' do
          before do
            actor.block!
          end

          it 'returns false' do
            expect(lfs_token.token_valid?(lfs_token.token)).to be false
          end
        end

        context 'when the user password is expired' do
          before do
            actor.update!(password_expires_at: 1.minute.ago)
          end

          it 'returns true' do
            expect(lfs_token.token_valid?(lfs_token.token)).to be true
          end
        end

        context 'when token was generated without project' do
          let(:project) { nil }

          it 'returns true (for backward compatibility)' do
            token_without_project = lfs_token.token

            expect(described_class.new(actor, create(:project)).token_valid?(token_without_project)).to be true
          end
        end

        context 'when token validation does not request a project' do
          it 'returns true' do
            token_with_project = lfs_token.token

            expect(described_class.new(actor, nil).token_valid?(token_with_project)).to be true
          end
        end
      end
    end
  end

  describe '#deploy_key_pushable?' do
    context 'when actor is not a DeployKey' do
      it 'returns false' do
        expect(lfs_token.deploy_key_pushable?(project)).to be false
      end
    end

    context 'when actor is a DeployKey' do
      let(:deploy_keys_project) { create(:deploy_keys_project, project: project, can_push: can_push) }
      let(:actor) { deploy_keys_project.deploy_key }

      context 'but the DeployKey cannot push to the project' do
        let(:can_push) { false }

        it 'returns false' do
          expect(lfs_token.deploy_key_pushable?(project)).to be false
        end
      end

      context 'and the DeployKey can push to the project' do
        let(:can_push) { true }

        it 'returns true' do
          expect(lfs_token.deploy_key_pushable?(project)).to be true
        end
      end
    end
  end

  describe '#type' do
    context 'when actor is not a User' do
      let(:actor) { deploy_key }

      it 'returns :lfs_deploy_token type' do
        expect(lfs_token.type).to eq(:lfs_deploy_token)
      end
    end

    context 'when actor is a User' do
      it 'returns :lfs_token type' do
        expect(lfs_token.type).to eq(:lfs_token)
      end
    end
  end

  describe '#authentication_payload' do
    it 'returns a Hash designed for gitlab-shell' do
      repo_http_path = 'http://localhost/user/repo.git'
      authentication_payload = lfs_token.authentication_payload(repo_http_path)

      expect(authentication_payload[:username]).to eq(actor.username)
      expect(authentication_payload[:repository_http_path]).to eq(repo_http_path)
      expect(authentication_payload[:lfs_token]).to be_a String
      expect(authentication_payload[:expires_in]).to eq(described_class::DEFAULT_EXPIRE_TIME)
    end
  end
end

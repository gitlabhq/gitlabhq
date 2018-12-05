require 'spec_helper'

describe Gitlab::LfsToken do
  describe '#token' do
    shared_examples 'an LFS token generator' do
      it 'returns a randomly generated token' do
        token = handler.token

        expect(token).not_to be_nil
        expect(token).to be_a String
        expect(token.length).to eq 50
      end

      it 'returns the correct token based on the key' do
        token = handler.token

        expect(handler.token).to eq(token)
      end
    end

    context 'when the actor is a user' do
      let(:actor) { create(:user) }
      let(:handler) { described_class.new(actor) }

      it_behaves_like 'an LFS token generator'

      it 'returns the correct username' do
        expect(handler.actor_name).to eq(actor.username)
      end

      it 'returns the correct token type' do
        expect(handler.type).to eq(:lfs_token)
      end
    end

    context 'when the actor is a deploy key' do
      let(:actor) { create(:deploy_key) }
      let(:handler) { described_class.new(actor) }

      it_behaves_like 'an LFS token generator'

      it 'returns the correct username' do
        expect(handler.actor_name).to eq("lfs+deploy-key-#{actor.id}")
      end

      it 'returns the correct token type' do
        expect(handler.type).to eq(:lfs_deploy_token)
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
end

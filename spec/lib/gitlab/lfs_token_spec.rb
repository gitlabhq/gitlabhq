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
end

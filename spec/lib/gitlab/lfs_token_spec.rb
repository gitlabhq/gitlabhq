require 'spec_helper'

describe Gitlab::LfsToken, lib: true do
  describe '#set_token and #get_value' do
    shared_examples 'an LFS token generator' do
      it 'returns a randomly generated token' do
        token = handler.generate

        expect(token).not_to be_nil
        expect(token).to be_a String
        expect(token.length).to eq 50
      end

      it 'returns the correct token based on the key' do
        token = handler.generate

        expect(handler.value).to eq(token)
      end
    end

    context 'when the actor is a user' do
      let(:actor) { create(:user) }
      let(:handler) { described_class.new(actor) }

      it_behaves_like 'an LFS token generator'
    end

    context 'when the actor is a deploy key' do
      let(:actor) { create(:deploy_key) }
      let(:handler) { described_class.new(actor) }

      it_behaves_like 'an LFS token generator'
    end
  end
end

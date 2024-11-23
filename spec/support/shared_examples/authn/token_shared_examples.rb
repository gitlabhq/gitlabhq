# frozen_string_literal: true

RSpec.shared_examples 'token handling with unsupported token type' do
  context 'with unsupported token type' do
    let_it_be(:plaintext) { 'unsupported' }

    describe '#initialize' do
      it 'is nil when the token type is not supported' do
        expect(token.revocable).to be_nil
      end
    end

    describe '#revoke!' do
      it 'raises error when the token type is not found' do
        expect do
          token.revoke!(user)
        end
          .to raise_error(::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found')
      end
    end
  end
end

RSpec.shared_examples 'finding the valid revocable' do
  describe '#initialize' do
    it 'finds the plaintext token' do
      expect(token.revocable).to eq(valid_revocable)
    end
  end

  describe '#present_with' do
    it 'returns a constant that is a subclass of Grape::Entity' do
      expect(token.present_with).to be <= Grape::Entity
    end
  end
end

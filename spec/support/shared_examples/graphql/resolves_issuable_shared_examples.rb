# frozen_string_literal: true

RSpec.shared_examples 'resolving an issuable in GraphQL' do |type|
  include GraphqlHelpers

  let(:parent_path) { parent.full_path }
  let(:iid) { issuable.iid }

  subject(:result) { mutation.resolve_issuable(type: type, parent_path: parent_path, iid: iid) }

  context 'when user has access' do
    before do
      parent.add_developer(current_user)
    end

    it 'resolves issuable by iid' do
      expect(result).to eq(issuable)
    end

    context 'the IID does not refer to a valid issuable' do
      let(:iid) { '100' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'the parent path is not present' do
      let(:parent_path) { '' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end
end

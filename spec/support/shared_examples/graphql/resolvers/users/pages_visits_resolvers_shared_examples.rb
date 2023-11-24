# frozen_string_literal: true

RSpec.shared_examples 'namespace visits resolver' do
  include GraphqlHelpers

  describe '#resolve' do
    context 'when user is not logged in' do
      let_it_be(:current_user) { nil }

      it 'returns nil' do
        expect(resolve_items).to eq(nil)
      end
    end

    context 'when user is logged in' do
      let_it_be(:current_user) { create(:user) }

      it 'returns frecent groups' do
        expect(resolve_items).to be_an_instance_of(Array)
      end
    end
  end

  private

  def resolve_items
    sync(resolve(described_class, ctx: { current_user: current_user }))
  end
end

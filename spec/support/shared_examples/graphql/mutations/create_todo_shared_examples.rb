# frozen_string_literal: true

RSpec.shared_examples 'create todo mutation' do
  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  context 'when user does not have permission to create todo' do
    it 'raises error' do
      expect { mutation.resolve(target_id: global_id_of(target)) }
        .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when user has permission to create todo' do
    it 'creates a todo' do
      target.resource_parent.add_reporter(current_user)

      result = mutation.resolve(target_id: global_id_of(target))

      expect(result[:todo]).to be_valid
      expect(result[:todo].target).to eq(target)
      expect(result[:todo].state).to eq('pending')
    end
  end
end

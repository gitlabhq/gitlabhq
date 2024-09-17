# frozen_string_literal: true

RSpec.shared_examples 'graphql notes subscriptions' do
  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:work_item) { create(:work_item, :task) }
    let_it_be(:note) { create(:note, noteable: work_item, project: work_item.project) }
    let_it_be(:current_user) { work_item.author }
    let_it_be(:noteable_id) { work_item.to_gid }

    subject { resolver.resolve_with_support(noteable_id: noteable_id) }

    context 'on initial subscription' do
      let(:resolver) do
        resolver_instance(described_class, ctx: query_context, subscription_update: false)
      end

      it 'returns nil' do
        expect(subject).to eq(nil)
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subject }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when work_item does not exist' do
        let(:noteable_id) { GlobalID.parse("gid://gitlab/WorkItem/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subject }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'on subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: note, ctx: query_context, subscription_update: true)
      end

      it 'returns the resolved object' do
        expect(subject).to eq(note)
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'unsubscribes the user' do
          # GraphQL::Execution::Execute::Skip is returned when unsubscribed
          expect(subject).to be_an(GraphQL::Execution::Execute::Skip)
        end
      end
    end
  end
end

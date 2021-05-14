# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ResolveTodosService do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(merge_request, user) }

  describe '#async_execute' do
    def async_execute
      service.async_execute
    end

    it 'performs MergeRequests::ResolveTodosWorker asynchronously' do
      expect(MergeRequests::ResolveTodosWorker)
        .to receive(:perform_async)
        .with(
          merge_request.id,
          user.id
        )

      async_execute
    end
  end

  describe '#execute' do
    it 'marks pending todo as done' do
      pending_todo = create(:todo, :pending, user: user, project: merge_request.project, target: merge_request)

      service.execute

      expect(pending_todo.reload).to be_done
    end
  end
end

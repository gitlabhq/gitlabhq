# frozen_string_literal: true

RSpec.shared_examples 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
  specify do
    expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(merge_request)

    action
  end
end

RSpec.shared_examples 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
  specify do
    expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated)

    action
  end
end

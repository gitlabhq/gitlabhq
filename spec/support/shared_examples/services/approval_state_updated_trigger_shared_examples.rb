# frozen_string_literal: true

RSpec.shared_examples 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
  specify do
    expect(GraphqlTriggers).to receive(:merge_request_approval_state_updated).with(merge_request)

    action
  end
end

RSpec.shared_examples 'does not trigger GraphQL subscription mergeRequestApprovalStateUpdated' do
  specify do
    expect(GraphqlTriggers).not_to receive(:merge_request_approval_state_updated)

    action
  end
end

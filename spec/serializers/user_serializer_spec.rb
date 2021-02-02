# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSerializer do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  context 'serializer with merge request context' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let(:serializer) { described_class.new(current_user: user1, merge_request_iid: merge_request.iid) }

    before do
      allow(project).to(
        receive_message_chain(:merge_requests, :find_by_iid!)
          .with(merge_request.iid).and_return(merge_request)
      )

      project.add_maintainer(user1)
    end

    it 'returns a user with can_merge option' do
      serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

      expect(serialized_user1).to include("id" => user1.id, "can_merge" => true)
      expect(serialized_user2).to include("id" => user2.id, "can_merge" => false)
    end
  end
end

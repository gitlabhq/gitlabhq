# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::BaseService, feature_category: :groups_and_projects do
  let_it_be(:access_requester) { create(:group_member) }

  describe '#resolve_access_request_todos' do
    it 'calls the resolve_access_request_todos of todo service' do
      expect_next_instance_of(TodoService) do |todo_service|
        expect(todo_service)
          .to receive(:resolve_access_request_todos).with(access_requester)
      end

      described_class.new.send(:resolve_access_request_todos, access_requester)
    end
  end
end

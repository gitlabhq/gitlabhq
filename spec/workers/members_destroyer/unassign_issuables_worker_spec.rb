# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MembersDestroyer::UnassignIssuablesWorker do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user, reload: true) { create(:user) }

  context 'when unsupported membership source entity' do
    it 'exits early and logs error' do
      params = { message: "SomeEntity is not a supported entity.", entity_type: 'SomeEntity', entity_id: group.id, user_id: user.id }

      expect(Sidekiq.logger).to receive(:error).with(params)

      described_class.new.perform(user.id, group.id, 'SomeEntity')
    end
  end

  it "calls the Members::UnassignIssuablesService with the params it was given" do
    service = double

    expect(Members::UnassignIssuablesService).to receive(:new).with(user, group).and_return(service)
    expect(service).to receive(:execute)

    described_class.new.perform(user.id, group.id, 'Group')
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'boards recent visit create service' do
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(board.resource_parent, user) }

  it 'returns nil when there is no user' do
    service.current_user = nil

    expect(service.execute(board)).to be_nil
  end

  it 'returns nil when database is read only' do
    allow(Gitlab::Database).to receive(:read_only?) { true }

    expect(service.execute(board)).to be_nil
  end

  it 'records the visit' do
    expect(model).to receive(:visited!).once

    service.execute(board)
  end
end

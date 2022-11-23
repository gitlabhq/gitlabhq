# frozen_string_literal: true

RSpec.shared_context 'when user tracking is disabled' do
  before do
    # rubocop:disable RSpec/AnyInstanceOf
    allow_any_instance_of(User).to receive(:update_tracked_fields!)
    allow_any_instance_of(Users::ActivityService).to receive(:execute)
    # rubocop:enable RSpec/AnyInstanceOf
  end
end

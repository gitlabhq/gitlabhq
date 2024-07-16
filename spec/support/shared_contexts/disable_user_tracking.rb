# frozen_string_literal: true

RSpec.shared_context 'when user tracking is disabled' do
  before do
    # rubocop:disable RSpec/AnyInstanceOf
    allow_any_instance_of(User).to receive(:update_tracked_fields!)
    # rubocop:enable RSpec/AnyInstanceOf

    allow_next_instance_of(Users::ActivityService) do |service|
      allow(service).to receive(:execute)
    end
  end
end

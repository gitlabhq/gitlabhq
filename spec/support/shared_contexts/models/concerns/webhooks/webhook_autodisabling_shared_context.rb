# frozen_string_literal: true

RSpec.shared_context 'with webhook auto-disabling failure thresholds' do
  where(:recent_failures, :disabled_until, :executable) do
    past = 1.minute.ago
    now = Time.current
    future = 1.minute.from_now

    [
      # At 3 failures the hook is always executable
      [3, nil, true],
      [3, past, true],
      [3, now, true],
      [3, future, true],
      # At 4 failures the hook is executable only when disabled_until is in the past
      [4, nil, false],
      [4, past, true],
      [4, now, true],
      [4, future, false],
      # At 39 failures the logic should be the same as with 4 failures (testing the boundary of 40)
      [39, nil, false],
      [39, past, true],
      [39, now, true],
      [39, future, false],
      # At 40 failures the hook is always disabled
      [40, nil, false],
      [40, past, false],
      [40, now, false],
      [40, future, false]
    ]
  end
end

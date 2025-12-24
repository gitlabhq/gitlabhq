# frozen_string_literal: true

module Namespaces
  module StatefulHelpers
    # Helper method to set state bypassing validations
    def set_state(record, state_symbol)
      record.update_column(:state, Namespaces::Stateful::STATES[state_symbol])
      record.reload
    end
  end
end

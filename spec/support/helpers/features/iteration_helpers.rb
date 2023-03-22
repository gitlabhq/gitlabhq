# frozen_string_literal: true

module Features
  module IterationHelpers
    def iteration_period(iteration)
      "#{iteration.start_date.to_s(:medium)} - #{iteration.due_date.to_s(:medium)}"
    end
  end
end

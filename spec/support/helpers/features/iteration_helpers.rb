# frozen_string_literal: true

module Features
  module IterationHelpers
    def iteration_period(iteration)
      "#{iteration.start_date.to_fs(:medium)} - #{iteration.due_date.to_fs(:medium)}"
    end
  end
end

# frozen_string_literal: true

module Features
  module IterationHelpers
    def iteration_period(iteration)
      "#{iteration.start_date.to_fs(:medium)} - #{iteration.due_date.to_fs(:medium)}"
    end

    def iteration_period_display_no_year(iteration)
      "#{iteration.start_date.strftime('%b %-d')} - #{iteration.due_date.strftime('%b %-d')}"
    end

    def iteration_period_display(iteration)
      "#{iteration.start_date.strftime('%b %-d')} - #{iteration.due_date.strftime('%b %-d, %Y')}"
    end
  end
end

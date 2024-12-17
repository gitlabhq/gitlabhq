# frozen_string_literal: true

module Features
  module IterationHelpers
    def iteration_period(iteration, use_thin_space: true)
      start_date = iteration.start_date
      due_date = iteration.due_date
      # Capybara can have issues with irregular whitespaces
      # This provides an alternative for selectors to use
      # regular whitespaces
      separator = use_thin_space ? " – " : " – "

      if start_date.year == due_date.year
        if start_date.month == due_date.month
          # Same year and same month: show only the day for the start date
          # and full format for the due date.
          "#{start_date.strftime('%b %-d')}#{separator}#{due_date.strftime('%-d, %Y')}"
        else
          # Same year but different month: show full start date and month/day for the due date.
          "#{start_date.strftime('%b %-d')}#{separator}#{due_date.strftime('%b %-d, %Y')}"
        end
      else
        # Different year: show the full format for both dates.
        "#{start_date.strftime('%b %-d, %Y')}#{separator}#{due_date.strftime('%b %-d, %Y')}"
      end
    end
  end
end

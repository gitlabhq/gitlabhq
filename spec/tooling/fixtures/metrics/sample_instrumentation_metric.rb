# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ActiveUserCountMetric < DatabaseMetric
          operation :count

          relation { SuperUser.active }
        end
      end
    end
  end
end

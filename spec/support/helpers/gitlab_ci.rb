# frozen_string_literal: true

module Support
  module GitlabCi
    module_function

    def predictive_job?
      ENV['CI_JOB_NAME']&.include?('predictive')
    end

    def fail_fast_job?
      ENV['CI_JOB_NAME']&.include?('fail-fast')
    end
  end
end

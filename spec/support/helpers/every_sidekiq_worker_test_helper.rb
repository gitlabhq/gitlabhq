# frozen_string_literal: true

module EverySidekiqWorkerTestHelper
  def extra_retry_exceptions
    {}
  end
end

EverySidekiqWorkerTestHelper.prepend_mod

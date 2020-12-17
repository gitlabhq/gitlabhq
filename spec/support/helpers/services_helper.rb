# frozen_string_literal: true

require_relative './after_next_helpers'

module ServicesHelper
  include AfterNextHelpers

  def expect_execution_of(service_class, *args)
    expect_next(service_class, *args).to receive(:execute)
  end
end

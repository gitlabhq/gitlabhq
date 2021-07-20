# frozen_string_literal: true

# named as `get_executed` to avoid clashing
# with `be_executed === have_attributes(executed: true)`
RSpec::Matchers.define :get_executed do |args = []|
  include AfterNextHelpers

  match do |service_class|
    expect_next(service_class, *args).to receive(:execute)
  end
end

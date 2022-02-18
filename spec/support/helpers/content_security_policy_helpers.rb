# frozen_string_literal: true

module ContentSecurityPolicyHelpers
  # Expecting 2 calls to current_content_security_policy by default, once for
  # the call that's being tested and once for the call in ApplicationController
  def setup_csp_for_controller(controller_class, times = 2)
    expect_next_instance_of(controller_class) do |controller|
      expect(controller).to receive(:current_content_security_policy)
                              .and_return(ActionDispatch::ContentSecurityPolicy.new).exactly(times).times
    end
  end

  # Expecting 2 calls to current_content_security_policy by default, once for
  # the call that's being tested and once for the call in ApplicationController
  def setup_existing_csp_for_controller(controller_class, csp, times = 2)
    expect_next_instance_of(controller_class) do |controller|
      expect(controller).to receive(:current_content_security_policy).and_return(csp).exactly(times).times
    end
  end
end

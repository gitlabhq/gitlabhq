# frozen_string_literal: true

module ContentSecurityPolicyHelpers
  # Expecting 2 calls to current_content_security_policy by default:
  # 1. call that's being tested
  # 2. call in ApplicationController
  def setup_csp_for_controller(controller_class, csp = ActionDispatch::ContentSecurityPolicy.new, times: 2)
    expect_next_instance_of(controller_class) do |controller|
      expect(controller)
        .to receive(:current_content_security_policy).exactly(times).times
        .and_return(csp)
    end
  end
end

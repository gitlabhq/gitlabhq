# frozen_string_literal: true

module ContentSecurityPolicyHelpers
  def stub_csp_for_controller(controller_class, csp = ActionDispatch::ContentSecurityPolicy.new)
    allow_next_instance_of(controller_class) do |controller|
      allow(controller).to receive(:current_content_security_policy).and_return(csp)
    end
  end

  # Finds the given csp directive values as an array
  #
  # Example:
  # ```
  # find_csp_directive('connect-src')
  # ```
  def find_csp_directive(key, header: nil)
    csp = header || response.headers['Content-Security-Policy']

    # Transform "default-src foo bar; connect-src foo bar; script-src ..."
    # into array of values for a single directive based on the given key
    csp.split(';')
      .map(&:strip)
      .find { |entry| entry.starts_with?(key) }
      .split(' ')
      .drop(1)
  end
end

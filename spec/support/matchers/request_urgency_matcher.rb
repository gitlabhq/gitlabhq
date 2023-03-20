# frozen_string_literal: true

require 'spec_helper'

module RequestUrgencyMatcher
  RSpec::Matchers.define :have_request_urgency do |request_urgency|
    match do |_actual|
      if controller_instance = request.env["action_controller.instance"]
        controller_instance.urgency.name == request_urgency
      elsif endpoint = request.env['api.endpoint']
        urgency = endpoint.options[:for].try(:urgency_for_app, endpoint)
        urgency.name == request_urgency
      else
        raise 'neither a controller nor a request spec'
      end
    end

    failure_message do |_actual|
      if controller_instance = request.env["action_controller.instance"]
        "request urgency #{controller_instance.urgency.name} is set, \
          but expected to be #{request_urgency}".squish
      elsif endpoint = request.env['api.endpoint']
        urgency = endpoint.options[:for].try(:urgency_for_app, endpoint)
        "request urgency #{urgency.name} is set, \
          but expected to be #{request_urgency}".squish
      end
    end
  end
end

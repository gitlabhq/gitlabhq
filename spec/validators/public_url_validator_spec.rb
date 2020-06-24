# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PublicUrlValidator do
  include_examples 'url validator examples', AddressableUrlValidator::DEFAULT_OPTIONS[:schemes]
  include_examples 'public url validator examples', allow_local_requests_from_web_hooks_and_services: true
end

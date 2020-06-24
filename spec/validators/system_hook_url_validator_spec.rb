# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHookUrlValidator do
  include_examples 'url validator examples', AddressableUrlValidator::DEFAULT_OPTIONS[:schemes]
  include_examples 'public url validator examples', allow_local_requests_from_system_hooks: true
end

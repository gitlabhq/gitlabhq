# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.describe API::Markdown, 'Snapshot' do
  # noinspection RubyMismatchedArgumentType (ignore RBS type warning: __dir__ can be nil, but 2nd argument can't be nil)
  glfm_specification_dir = File.expand_path('../../../glfm_specification', __dir__)
  include_context 'with API::Markdown Snapshot shared context', glfm_specification_dir
end

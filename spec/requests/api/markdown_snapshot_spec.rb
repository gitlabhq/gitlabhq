# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.describe API::Markdown, 'Snapshot' do
  glfm_specification_dir = File.expand_path('../../../glfm_specification', __dir__)
  glfm_example_snapshots_dir = File.expand_path('../../fixtures/glfm/example_snapshots', __dir__)
  include_context 'with API::Markdown Snapshot shared context', glfm_specification_dir, glfm_example_snapshots_dir
end

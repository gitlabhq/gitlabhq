# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.describe API::Markdown, 'Snapshot' do
  glfm_example_snapshots_dir = File.expand_path('../../fixtures/glfm/example_snapshots', __dir__)
  include_context 'API::Markdown Snapshot shared context', glfm_example_snapshots_dir
end

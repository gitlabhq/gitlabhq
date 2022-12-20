# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.describe API::Markdown, 'Snapshot', feature_category: :team_planning do
  include_context 'with API::Markdown Snapshot shared context'
end

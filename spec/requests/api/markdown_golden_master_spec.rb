# frozen_string_literal: true

require 'spec_helper'

# See spec/fixtures/markdown/markdown_golden_master_examples.yml for documentation on how this spec works.
RSpec.describe API::Markdown, 'Golden Master', feature_category: :team_planning do
  markdown_yml_file_path = File.expand_path('../../fixtures/markdown/markdown_golden_master_examples.yml', __dir__)
  include_context 'API::Markdown Golden Master shared context', markdown_yml_file_path
end

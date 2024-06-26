# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../../tooling/danger/specs'
require_relative '../../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Specs::FeatureCategorySuggestion, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(Tooling::Danger::Specs) }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { 'spec/foo_spec.rb' }
  let(:feature_category) { ', feature_category: <see config/feature_categories.yml>' }

  let(:template) do
    <<~SUGGESTION_MARKDOWN.chomp
    ```suggestion
    %<suggested_line>s
    ```

    Consider adding `feature_category: <feature_category_name>` for this example if it is not set already.
    See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata).
    SUGGESTION_MARKDOWN
  end

  let(:file_lines) do
    [
      " require 'spec_helper'",
      " \n",
      " RSpec.describe Projects::SummaryController, feature_category: :team_planning do",
      " end",
      "RSpec.describe Projects::SummaryController do",
      "  let_it_be(:user) { create(:user) }",
      " end",
      " describe 'GET \"time_summary\"' do",
      " end",
      " RSpec.describe Projects::SummaryController, foo: :bar do",
      "  let_it_be(:user) { create(:user) }",
      " end",
      " describe 'GET \"time_summary\"' do",
      " end",
      " \n",
      "RSpec.describe Projects, :aggregate_failures,",
      "  feature_category :team_planning do",
      " \n",
      "RSpec.describe Epics, :aggregate_failures,",
      "  ee: true do",
      "\n",
      "RSpec.describe Issues, :aggregate_failures,",
      "  feature_category: :team_planning do",
      "\n",
      "RSpec.describe MergeRequest, :aggregate_failures,",
      "  :js,",
      "  feature_category: :team_planning do"
    ]
  end

  let(:changed_lines) do
    [
      "+ RSpec.describe Projects::SummaryController, feature_category: :team_planning do",
      "+RSpec.describe Projects::SummaryController do",
      "+ let_it_be(:user) { create(:user) }",
      "- end",
      "+ describe 'GET \"time_summary\"' do",
      "+ RSpec.describe Projects::SummaryController, foo: :bar do",
      "+RSpec.describe Projects, :aggregate_failures,",
      "+  feature_category: :team_planning do",
      "+RSpec.describe Epics, :aggregate_failures,",
      "+  ee: true do",
      "+RSpec.describe Issues, :aggregate_failures,",
      "+RSpec.describe MergeRequest :aggregate_failures,",
      "+  :js,",
      "+  feature_category: :team_planning do",
      "+RSpec.describe 'line in commit diff but no longer in working copy' do"
    ]
  end

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
    allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
  end

  it 'adds suggestions at the correct lines', :aggregate_failures do
    [
      { suggested_line: "RSpec.describe Projects::SummaryController#{feature_category} do", number: 5 },
      { suggested_line: " RSpec.describe Projects::SummaryController, foo: :bar#{feature_category} do", number: 10 },
      { suggested_line: "RSpec.describe Epics, :aggregate_failures#{feature_category},", number: 19 }

    ].each do |test_case|
      comment = format(template, suggested_line: test_case[:suggested_line])
      expect(specs).to receive(:markdown).with(comment, file: filename, line: test_case[:number])
    end

    specs.add_suggestions_for(filename)
  end
end

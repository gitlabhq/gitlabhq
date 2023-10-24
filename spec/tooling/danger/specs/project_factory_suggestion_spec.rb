# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../../tooling/danger/specs'
require_relative '../../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Specs::ProjectFactorySuggestion, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(Tooling::Danger::Specs) }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { 'spec/foo_spec.rb' }

  let(:template) do
    <<~MARKDOWN.chomp
      ```suggestion
      %<suggested_line>s
      ```

      Project creations are very slow. To improve test performance, consider using `let_it_be`, `build`, or `build_stubbed` instead.

      ⚠️ **Warning**: If your test modifies data, `let_it_be` may be unsuitable, and cause state leaks! Use `let_it_be_with_reload` or `let_it_be_with_refind` instead.

      Unsure which method to use? See the [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage)
      for background information and alternative options for optimizing factory usage.

      If you're concerned about causing state leaks, or if you know `let` or `let!` are the better options, ignore this comment.

      ([Improve this message?](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/specs/project_factory_suggestion.rb))
    MARKDOWN
  end

  let(:file_lines) do
    [
      " let(:project) { create(:project) }",
      " let_it_be(:project) { create(:project, :repository)",
      " let!(:project) { create(:project) }",
      "   let(:var) { create(:project) }",
      " let(:merge_request) { create(:merge_request, project: project)",
      " context 'when merge request exists' do",
      "   it { is_expected.to be_success }",
      " end",
      "   let!(:var) { create(:project) }",
      " let(:project) { create(:thing) }",
      " let(:project) { build(:project) }",
      " let(:project) do",
      "   create(:project)",
      " end",
      " let(:project) { create(:project, :repository) }",
      " str = 'let(:project) { create(:project) }'",
      " let(:project) { create(:project_empty_repo) }",
      " let(:project) { create(:forked_project_with_submodules) }",
      " let(:project) { create(:project_with_design) }",
      " let(:authorization) { create(:project_authorization) }"
    ]
  end

  let(:matching_lines) do
    [
      "+ let(:should_not_error) { create(:project) }",
      "+ let(:project) { create(:project) }",
      "+ let!(:project) { create(:project) }",
      "+   let(:var) { create(:project) }",
      "+   let!(:var) { create(:project) }",
      "+ let(:project) { create(:project, :repository) }",
      "+ let(:project) { create(:project_empty_repo) }",
      "+ let(:project) { create(:forked_project_with_submodules) }",
      "+ let(:project) { create(:project_with_design) }"
    ]
  end

  let(:changed_lines) do
    [
      "+ line which doesn't exist in the file and should not cause an error",
      "+ let_it_be(:project) { create(:project, :repository)",
      "+ let(:project) { create(:thing) }",
      "+ let(:project) do",
      "+   create(:project)",
      "+ end",
      "+ str = 'let(:project) { create(:project) }'",
      "+ let(:authorization) { create(:project_authorization) }"
    ] + matching_lines
  end

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
    allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
  end

  it 'adds suggestions at the correct lines', :aggregate_failures do
    [
      { suggested_line: " let_it_be(:project) { create(:project) }", number: 1 },
      { suggested_line: " let_it_be(:project) { create(:project) }", number: 3 },
      { suggested_line: "   let_it_be(:var) { create(:project) }", number: 4 },
      { suggested_line: "   let_it_be(:var) { create(:project) }", number: 9 },
      { suggested_line: " let_it_be(:project) { create(:project, :repository) }", number: 15 },
      { suggested_line: " let_it_be(:project) { create(:project_empty_repo) }", number: 17 },
      { suggested_line: " let_it_be(:project) { create(:forked_project_with_submodules) }", number: 18 },
      { suggested_line: " let_it_be(:project) { create(:project_with_design) }", number: 19 }
    ].each do |test_case|
      comment = format(template, suggested_line: test_case[:suggested_line])
      expect(specs).to receive(:markdown).with(comment, file: filename, line: test_case[:number])
    end

    specs.add_suggestions_for(filename)
  end
end

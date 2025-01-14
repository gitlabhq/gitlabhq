# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/rubocop_discourage_todo_addition'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RubocopDiscourageTodoAddition, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { '.rubocop_todo/foo.yml' }
  let(:template) { Tooling::Danger::RubocopDiscourageTodoAddition::SUGGESTION }
  let(:file_lines) do
    <<~YML.split("\n")
      ---
      RSpec/AvoidConditionalStatements:
        Exclude:
          - 'ee/spec/features/admin/admin_settings_spec.rb'
          - 'ee/spec/features/analytics/code_analytics_spec.rb'
          - 'ee/spec/features/foo_spec.rb'
          - 'ee/spec/features/billings/billing_plans_spec.rb'
          - 'ee/spec/features/boards/scoped_issue_board_spec.rb'
          - 'ee/spec/features/boards/user_visits_board_spec.rb'
          - 'ee/spec/features/bar_spec.rb'
          - 'ee/spec/features/epic_boards/epic_boards_spec.rb'
    YML
  end

  let(:changed_lines) do
    <<~DIFF.split("\n")
      +    - 'ee/spec/features/foo_spec.rb'
      +    - 'ee/spec/features/bar_spec.rb'
    DIFF
  end

  subject(:rubocop) { fake_danger.new(helper: fake_helper) }

  before do
    allow(rubocop).to receive(:project_helper).and_return(fake_project_helper)
    allow(rubocop.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(rubocop.project_helper).to receive(:file_lines).and_return(file_lines)

    rubocop.define_singleton_method(:add_todo_suggestion_for) do |filename|
      Tooling::Danger::RubocopDiscourageTodoAddition.new(filename, context: self).suggest
    end
  end

  it 'adds only one comment in the file' do
    expect(rubocop).to receive(:markdown).with("\n#{template}".chomp, file: filename, line: 6)

    rubocop.add_todo_suggestion_for(filename)
  end

  context 'with grace period changes' do
    let(:file_lines) do
      <<~YML.split("\n")
        ---
        RSpec/AvoidConditionalStatements:
          Details: grace period
          Exclude:
            - 'ee/spec/features/analytics/code_analytics_spec.rb'
            - 'ee/spec/features/foo_spec.rb'
      YML
    end

    let(:basic_diff_lines) do
      <<~DIFF.split("\n")
        +    - 'ee/spec/features/foo_spec.rb'
        +    - 'ee/spec/features/bar_spec.rb'
      DIFF
    end

    let(:changed_lines) { basic_diff_lines }

    shared_examples_for 'no_suggestions_for_file' do
      it 'ignores the file' do
        expect(rubocop).not_to receive(:markdown)

        rubocop.add_todo_suggestion_for(filename)
      end
    end

    context 'when grace period exists and is not part of the change' do
      it_behaves_like 'no_suggestions_for_file'
    end

    context 'when grace period exists and is added as part of the change' do
      let(:changed_lines) { basic_diff_lines.prepend('+  Details: grace period') }

      it_behaves_like 'no_suggestions_for_file'
    end

    context 'when grace period exists and is removed as part of the change' do
      let(:file_lines) do
        <<~YML.split("\n")
          ---
          RSpec/AvoidConditionalStatements:
            Exclude:
              - 'ee/spec/features/analytics/code_analytics_spec.rb'
              - 'ee/spec/features/foo_spec.rb'
        YML
      end

      let(:changed_lines) { basic_diff_lines.prepend('-  Details: grace period') }

      it_behaves_like 'no_suggestions_for_file'
    end
  end
end

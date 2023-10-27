# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/rubocop_inline_disable_suggestion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RubocopInlineDisableSuggestion, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { 'spec/foo_spec.rb' }

  let(:template) do
    <<~SUGGESTION_MARKDOWN.chomp
    ```suggestion
    %<suggested_line>s
    ```

    Consider removing this inline disabling and adhering to the rubocop rule.

    If that isn't possible, please provide the reason as a code comment in the
    same line where the rule is disabled separated by ` -- `.
    See [rubocop best practices](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#disabling-rules-inline).

    ----

    [Improve this message](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/rubocop_inline_disable_suggestion.rb)
    or [have feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/428157)?
    SUGGESTION_MARKDOWN
  end

  let(:file_lines) do
    <<~RUBY.split("\n")
      def validate_credit_card?(project)
        !current_user.has_required_credit_card_to_enable_shared_runners?(project)
        return true if Gitlab.com? # rubocop:disable Some/Cop
      end

      def show_buy_pipeline_minutes?(project, namespace)
        return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_pipeline_minutes_notification_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_other_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop: disable Gitlab/AvoidGitlabInstanceChecks
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_my_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop:todo Gitlab/AvoidGitlabInstanceChecks
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_my_other_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_my_new_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks -- Reason for disabling
        thatsfine = "".dup # rubocop:disable Lint/UselessAssignment,Performance/UnfreezeString -- That's OK
        me = "".dup # rubocop:disable Lint/UselessAssignment,Performance/UnfreezeString
        test = "".dup # rubocop:disable Lint/UselessAssignment, Performance/UnfreezeString
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end

      def show_my_bad_dot?(project, namespace)
        return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks --
        return false if notification_dot_acknowledged?

        show_out_of_pipeline_minutes_notification?(project, namespace)
      end
    RUBY
  end

  let(:changed_lines) do
    <<~DIFF.split("\n")
      +  return true if Gitlab.com? # rubocop:disable Some/Cop
      +end
      +  return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop: disable Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop:todo Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks
      +  return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks -- Reason for disabling
      +  me = "".dup # rubocop:disable Lint/UselessAssignment,Performance/UnfreezeString
      +  test = "".dup # rubocop:disable Lint/UselessAssignment, Performance/UnfreezeString
      +  return false unless ::Gitlab.com? # rubocop: todo Gitlab/AvoidGitlabInstanceChecks --
    DIFF
  end

  subject(:rubocop) { fake_danger.new(helper: fake_helper) }

  before do
    allow(rubocop).to receive(:project_helper).and_return(fake_project_helper)
    allow(rubocop.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(rubocop.project_helper).to receive(:file_lines).and_return(file_lines)

    rubocop.define_singleton_method(:add_suggestions_for) do |filename|
      Tooling::Danger::RubocopInlineDisableSuggestion.new(filename, context: self).suggest
    end
  end

  it 'adds comments at the correct lines', :aggregate_failures do
    [3, 7, 13, 20, 27, 34, 41, 50, 51, 58].each do |line_number|
      existing_line = file_lines[line_number - 1].sub(/ --\s*$/, '')
      suggested_line = "#{existing_line} -- TODO: Reason why the rule must be disabled"
      comment = format(template, suggested_line: suggested_line)

      expect(rubocop).to receive(:markdown).with(comment, file: filename, line: line_number)
    end

    rubocop.add_suggestions_for(filename)
  end
end

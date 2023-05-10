# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/avoid_conditional_statements'

RSpec.describe RuboCop::Cop::RSpec::AvoidConditionalStatements, feature_category: :tooling do
  context 'when using conditionals' do
    it 'flags if conditional' do
      expect_offense(<<~RUBY)
        if page.has_css?('[data-testid="begin-commit-button"]')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use `if` conditional statement in specs, it might create flakiness. See https://gitlab.com/gitlab-org/gitlab/-/issues/385304#note_1345437109
          find('[data-testid="begin-commit-button"]').click
        end
      RUBY
    end

    it 'flags unless conditional' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Multi-file editor new directory', :js, feature_category: :web_ide do
          it 'creates directory in current directory' do
            unless page.has_css?('[data-testid="begin-commit-button"]')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use `unless` conditional statement in specs, it might create flakiness. See https://gitlab.com/gitlab-org/gitlab/-/issues/385304#note_1345437109
              find('[data-testid="begin-commit-button"]').click
            end
          end
        end
      RUBY
    end

    it 'flags ternary operator' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Multi-file editor new directory', :js, feature_category: :web_ide do
          it 'creates directory in current directory' do
            user.present ? user : nil
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use `user.present ? user : nil` conditional statement in specs, it might create flakiness. See https://gitlab.com/gitlab-org/gitlab/-/issues/385304#note_1345437109
          end
        end
      RUBY
    end
  end
end

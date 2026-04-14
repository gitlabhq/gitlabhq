# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gettext/pascal_case_namespace'

RSpec.describe RuboCop::Cop::Gettext::PascalCaseNamespace, feature_category: :internationalization do
  describe '#s_()' do
    it 'does not flag valid namespaces' do
      expect_no_offenses(<<~'RUBY')
        s_('MyNamespace|Hello')
        s_('Wiki404|Page not found')
        s_('ClusterIntegration|Learn more')
        s_('Hello | World')
        s_('Hello')
      RUBY
    end

    it 'flags a namespace with underscores' do
      expect_offense(<<~'RUBY')
        s_('Test_i18n|Hello')
           ^^^^^^^^^^^^^^^^^ Namespace `Test_i18n` must be in PascalCase format, spaces and underscores are not valid.
      RUBY
    end

    it 'flags a namespace with spaces' do
      expect_offense(<<~'RUBY')
        s_('Add passkey|Add passkey')
           ^^^^^^^^^^^^^^^^^^^^^^^^^ Namespace `Add passkey` must be in PascalCase format, spaces and underscores are not valid.
      RUBY
    end

    it 'flags a namespace with multiple words' do
      expect_offense(<<~'RUBY')
        s_('Time Display|System')
           ^^^^^^^^^^^^^^^^^^^^^ Namespace `Time Display` must be in PascalCase format, spaces and underscores are not valid.
      RUBY
    end

    it 'flags a lowercase namespace' do
      expect_offense(<<~'RUBY')
        s_('my_namespace|Hello')
           ^^^^^^^^^^^^^^^^^^^^ Namespace `my_namespace` must be in PascalCase format, spaces and underscores are not valid.
      RUBY
    end

    describe('when PascalCase is not strictly followed') do
      it 'does not flag an all-lowercase namespace' do
        expect_no_offenses(<<~'RUBY')
        s_('foo|Hello')
        RUBY
      end

      it 'does not flag an all-uppercase namespace' do
        expect_no_offenses(<<~'RUBY')
        s_('FOO|Hello')
        RUBY
      end
    end

    it 'does not flag when the argument is a variable' do
      expect_no_offenses(<<~'RUBY')
        s_(variable) # This is to satisfy undercoverage. In reality there is another cop that covers this bad use case.
      RUBY
    end

    it 'flags a namespace in a split string' do
      expect_offense(<<~'RUBY')
        s_('my_namespace|Hello' \
           ^^^^^^^^^^^^^^^^^^^^^^ Namespace `my_namespace` must be in PascalCase format, spaces and underscores are not valid.
           'World')
      RUBY
    end

    it 'does not flag when the argument is a pure interpolation' do
      expect_no_offenses(<<~'RUBY')
        s_("#{namespace}|Hello") # This is to satisfy undercoverage. In reality there is another cop that covers this bad use case.
      RUBY
    end
  end

  describe '#n_()' do
    it 'does not flag valid namespaces' do
      expect_no_offenses(<<~'RUBY')
        n_('MergeRequest|Apple', 'MergeRequest|Apples', count)
        n_('Wiki404|Item', 'Wiki404|Items', count)
      RUBY
    end

    it 'flags a namespace with spaces in both singular and plural' do
      expect_offense(<<~'RUBY')
        n_('Add passkey|Apple', 'Add passkey|Apples', count)
           ^^^^^^^^^^^^^^^^^^^ Namespace `Add passkey` must be in PascalCase format, spaces and underscores are not valid.
                                ^^^^^^^^^^^^^^^^^^^^ Namespace `Add passkey` must be in PascalCase format, spaces and underscores are not valid.
      RUBY
    end
  end
end

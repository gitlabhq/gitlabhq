# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/gettext/static_identifier'

RSpec.describe RuboCop::Cop::Gettext::StaticIdentifier, feature_category: :internationalization do
  describe '#_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~'RUBY')
        _('Hello')
        _('Hello #{name}')

        _('Hello %{name}') % { name: name }
        format(_('Hello %{name}') % { name: name })

        _('Hello' \
          'Multiline')
        _('Hello' \
          'Multiline %{name}') % { name: name }

        var = "Hello"
        _(var)
        _(method_name)
        list.each { |item| _(item) }
        _(CONST)
      RUBY
    end

    it 'flags incorrect use' do
      expect_offense(<<~'RUBY')
        _('Hello' + ' concat')
          ^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `_(...)`.
        _('Hello'.concat(' concat'))
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `_(...)`.
        _("Hello #{name}")
          ^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `_(...)`.
        _('Hello %{name}' % { name: name })
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `_(...)`.
        _(format('Hello %{name}') % { name: name })
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `_(...)`.
      RUBY
    end
  end

  describe '#N_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~'RUBY')
        N_('Hello')
        N_('Hello #{name}')
        N_('Hello %{name}') % { name: name }
        format(_('Hello %{name}') % { name: name })

        N_('Hello' \
           'Multiline')

        var = "Hello"
        N_(var)
        N_(method_name)
        list.each { |item| N_(item) }
        N_(CONST)
      RUBY
    end

    it 'flags incorrect use' do
      expect_offense(<<~'RUBY')
        N_('Hello' + ' concat')
           ^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `N_(...)`.
        N_("Hello #{name}")
           ^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `N_(...)`.
        N_('Hello %{name}' % { name: name })
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `N_(...)`.
        N_('Hello' \
           ^^^^^^^^^ Ensure to pass static strings to translation method `N_(...)`.
           'Multiline %{name}' % { name: name })
        N_(format('Hello %{name}') % { name: name })
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `N_(...)`.
      RUBY
    end
  end

  describe '#s_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~'RUBY')
        s_('World|Hello')
        s_('World|Hello #{name}')
        s_('World|Hello %{name}') % { name: name }
        format(s_('World|Hello %{name}') % { name: name })

        s_('World|Hello' \
           'Multiline')

        var = "Hello"
        s_(var)
        s_(method_name)
        list.each { |item| s_(item) }
        s_(CONST)
      RUBY
    end

    it 'flags incorrect use' do
      expect_offense(<<~'RUBY')
        s_("World|Hello #{name}")
           ^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `s_(...)`.
        s_('World|Hello' + ' concat')
           ^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `s_(...)`.
        s_('World|Hello %{name}' % { name: name })
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `s_(...)`.
        s_('World|Hello' \
           ^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `s_(...)`.
           'Multiline %{name}' % { name: name })
        s_(format('World|Hello %{name}') % { name: name })
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `s_(...)`.
      RUBY
    end
  end

  describe '#n_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~'RUBY')
        n_('Hello', 'Hellos', 2)
        n_('Hello', 'Hellos', count)

        n_('Hello' ' concat', 'Hellos', 2)
        n_('Hello', 'Hello' 's', 2)

        n_('Hello %{name}', 'Hellos %{name}', 2) % { name: name }
        format(n_('Hello %{name}', 'Hellos %{name}', count) % { name: name })

        n_('Hello', 'Hellos' \
           'Multiline', 2)

        n_('Hello' \
           'Multiline', 'Hellos', 2)

        n_('Hello' \
           'Multiline %{name}', 'Hellos %{name}', 2) % { name: name }

        var = "Hello"
        n_(var, var, 1)
        n_(method_name, method_name, count)
        list.each { |item| n_(item, item, 2) }
        n_(CONST, CONST, 2)
      RUBY
    end

    it 'flags incorrect use' do
      expect_offense(<<~'RUBY')
        n_('Hello' + ' concat', 'Hellos', 2)
           ^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
        n_('Hello', 'Hello' + 's', 2)
                    ^^^^^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
        n_("Hello #{name}", "Hellos", 2)
           ^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
        n_('Hello %{name}' % { name: name }, 'Hellos', 2)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
        n_('Hello' \
           ^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
           'Multiline %{name}' % { name: name }, 'Hellos %{name}', 2)
        n_('Hello', format('Hellos %{name}') % { name: name }, count)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Ensure to pass static strings to translation method `n_(...)`.
      RUBY
    end
  end

  describe 'edge cases' do
    it 'does not flag' do
      expect_no_offenses(<<~RUBY)
        n_(s_('World|Hello'), s_('World|Hellos'), 2)
      RUBY
    end
  end
end

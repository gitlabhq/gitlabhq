# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/inject_enterprise_edition_module'

RSpec.describe RuboCop::Cop::InjectEnterpriseEditionModule do
  subject(:cop) { described_class.new }

  it 'flags the use of `prepend_mod_with` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_mod_with('Foo')
      ^^^^^^^^^^^^^^^^^^^^^^^ Injecting extension modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `include_mod_with` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      include_mod_with('Foo')
      ^^^^^^^^^^^^^^^^^^^^^^^ Injecting extension modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end
  it 'flags the use of `extend_mod_with` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      extend_mod_with('Foo')
      ^^^^^^^^^^^^^^^^^^^^^^ Injecting extension modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'does not flag the use of `prepend_mod_with` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.prepend_mod_with('Foo')
    SOURCE
  end

  it 'does not flag the use of `include_mod_with` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.include_mod_with('Foo')
    SOURCE
  end

  it 'does not flag the use of `extend_mod_with` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.extend_mod_with('Foo')
    SOURCE
  end

  it 'does not flag the double use of `X_mod_with` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.extend_mod_with('Foo')
    Foo.include_mod_with('Foo')
    Foo.prepend_mod_with('Foo')
    SOURCE
  end

  it 'does not flag the use of `prepend_mod_with` as long as all injections are at the end of the file' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.include_mod_with('Foo')
    Foo.prepend_mod_with('Foo')

    Foo.include(Bar)
    # comment on prepending Bar
    Foo.prepend(Bar)
    SOURCE
  end

  it 'autocorrects offenses by just disabling the Cop' do
    expect_offense(<<~SOURCE)
      class Foo
        prepend_mod_with('Foo')
        ^^^^^^^^^^^^^^^^^^^^^^^ Injecting extension modules must be done on the last line of this file, outside of any class or module definitions
        include Bar
      end
    SOURCE

    expect_correction(<<~SOURCE)
      class Foo
        prepend_mod_with('Foo') # rubocop: disable Cop/InjectEnterpriseEditionModule
        include Bar
      end
    SOURCE
  end

  it 'disallows the use of prepend to inject an extension module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_mod_with`, `extend_mod_with`, or `prepend_mod_with`
    SOURCE
  end

  it 'disallows the use of prepend to inject a QA::EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend(QA::EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_mod_with`, `extend_mod_with`, or `prepend_mod_with`
    SOURCE
  end

  it 'disallows the use of extend to inject an EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.extend(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_mod_with`, `extend_mod_with`, or `prepend_mod_with`
    SOURCE
  end

  it 'disallows the use of include to inject an EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.include(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_mod_with`, `extend_mod_with`, or `prepend_mod_with`
    SOURCE
  end

  it 'disallows the use of prepend_mod_with without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend_mod_with(Foo)
                         ^^^ extension modules to inject must be specified as a String
    SOURCE
  end

  it 'disallows the use of include_mod_with without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.include_mod_with(Foo)
                         ^^^ extension modules to inject must be specified as a String
    SOURCE
  end

  it 'disallows the use of extend_mod_with without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.extend_mod_with(Foo)
                        ^^^ extension modules to inject must be specified as a String
    SOURCE
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/inject_enterprise_edition_module'

describe RuboCop::Cop::InjectEnterpriseEditionModule do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of `prepend_if_ee EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee 'EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `prepend_if_ee QA::EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee 'QA::EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'does not flag the use of `prepend_if_ee EEFoo` in the middle of a file' do
    expect_no_offenses(<<~SOURCE)
    class Foo
      prepend_if_ee 'EEFoo'
    end
    SOURCE
  end

  it 'flags the use of `prepend_if_ee EE::Foo::Bar` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee 'EE::Foo::Bar'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `prepend_if_ee(EE::Foo::Bar)` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee('EE::Foo::Bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `prepend_if_ee EE::Foo::Bar::Baz` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee 'EE::Foo::Bar::Baz'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `prepend_if_ee ::EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      prepend_if_ee '::EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `include_if_ee EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      include_if_ee 'EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `include_if_ee ::EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      include_if_ee '::EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `extend_if_ee EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      extend_if_ee 'EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'flags the use of `extend_if_ee ::EE` in the middle of a file' do
    expect_offense(<<~SOURCE)
    class Foo
      extend_if_ee '::EE::Foo'
      ^^^^^^^^^^^^^^^^^^^^^^^^ Injecting EE modules must be done on the last line of this file, outside of any class or module definitions
    end
    SOURCE
  end

  it 'does not flag prepending of regular modules' do
    expect_no_offenses(<<~SOURCE)
    class Foo
      prepend_if_ee 'Foo'
    end
    SOURCE
  end

  it 'does not flag including of regular modules' do
    expect_no_offenses(<<~SOURCE)
    class Foo
      include_if_ee 'Foo'
    end
    SOURCE
  end

  it 'does not flag extending using regular modules' do
    expect_no_offenses(<<~SOURCE)
    class Foo
      extend_if_ee 'Foo'
    end
    SOURCE
  end

  it 'does not flag the use of `prepend_if_ee EE` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.prepend_if_ee('EE::Foo')
    SOURCE
  end

  it 'does not flag the use of `include_if_ee EE` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.include_if_ee('EE::Foo')
    SOURCE
  end

  it 'does not flag the use of `extend_if_ee EE` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.extend_if_ee('EE::Foo')
    SOURCE
  end

  it 'does not flag the double use of `X_if_ee` on the last line' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.extend_if_ee('EE::Foo')
    Foo.include_if_ee('EE::Foo')
    Foo.prepend_if_ee('EE::Foo')
    SOURCE
  end

  it 'does not flag the use of `prepend_if_ee EE` as long as all injections are at the end of the file' do
    expect_no_offenses(<<~SOURCE)
    class Foo
    end

    Foo.include_if_ee('EE::Foo')
    Foo.prepend_if_ee('EE::Foo')

    Foo.include(Bar)
    # comment on prepending Bar
    Foo.prepend(Bar)
    SOURCE
  end

  it 'autocorrects offenses by just disabling the Cop' do
    source = <<~SOURCE
    class Foo
      prepend_if_ee 'EE::Foo'
      include_if_ee 'Bar'
    end
    SOURCE

    expect(autocorrect_source(source)).to eq(<<~SOURCE)
    class Foo
      prepend_if_ee 'EE::Foo' # rubocop: disable Cop/InjectEnterpriseEditionModule
      include_if_ee 'Bar'
    end
    SOURCE
  end

  it 'disallows the use of prepend to inject an EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_if_ee`, `extend_if_ee`, or `prepend_if_ee`
    SOURCE
  end

  it 'disallows the use of prepend to inject a QA::EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend(QA::EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_if_ee`, `extend_if_ee`, or `prepend_if_ee`
    SOURCE
  end

  it 'disallows the use of extend to inject an EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.extend(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_if_ee`, `extend_if_ee`, or `prepend_if_ee`
    SOURCE
  end

  it 'disallows the use of include to inject an EE module' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.include(EE::Foo)
    ^^^^^^^^^^^^^^^^^^^^ EE modules must be injected using `include_if_ee`, `extend_if_ee`, or `prepend_if_ee`
    SOURCE
  end

  it 'disallows the use of prepend_if_ee without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.prepend_if_ee(EE::Foo)
                      ^^^^^^^ EE modules to inject must be specified as a String
    SOURCE
  end

  it 'disallows the use of include_if_ee without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.include_if_ee(EE::Foo)
                      ^^^^^^^ EE modules to inject must be specified as a String
    SOURCE
  end

  it 'disallows the use of extend_if_ee without a String' do
    expect_offense(<<~SOURCE)
    class Foo
    end

    Foo.extend_if_ee(EE::Foo)
                     ^^^^^^^ EE modules to inject must be specified as a String
    SOURCE
  end
end

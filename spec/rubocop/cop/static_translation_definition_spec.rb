# frozen_string_literal: true

require 'rubocop_spec_helper'

require 'rspec-parameterized'

require_relative '../../../rubocop/cop/static_translation_definition'

RSpec.describe RuboCop::Cop::StaticTranslationDefinition do
  using RSpec::Parameterized::TableSyntax

  let(:msg) { described_class::MSG }

  shared_examples 'offense' do |code|
    it 'registers an offense' do
      expect_offense(code)
    end
  end

  shared_examples 'no offense' do |code|
    it 'does not register an offense' do
      expect_no_offenses(code)
    end
  end

  describe 'offenses' do
    where(:code) do
      [
        <<~CODE,
          A = _("a")
              ^^^^^^ #{msg}
        CODE
        <<~CODE,
          B = s_("b")
              ^^^^^^^ #{msg}
        CODE
        <<~CODE,
          C = n_("c")
              ^^^^^^^ #{msg}
        CODE
        <<~'CODE',
          A = _('a' \
              ^^^^^^^ [...]
                'b')
        CODE
        <<~'CODE',
          A = _("a#{s}")
              ^^^^^^^^^^ [...]
        CODE
        <<~CODE,
          class MyClass
            def self.translations
              @cache ||= { hello: _("hello") }
                                  ^^^^^^^^^^ #{msg}
            end
          end
        CODE
        <<~CODE,
          module MyModule
            A = {
              b: {
                c: _("a")
                   ^^^^^^ #{msg}
              }
            }
          end
        CODE
        <<~CODE,
          class MyClass
            B = [
              [
                s_("a")
                ^^^^^^^ #{msg}
              ]
            ]
          end
        CODE
        <<~CODE,
          class MyClass
            field :foo, title: _('A title')
                               ^^^^^^^^^^^^ #{msg}
          end
        CODE
        <<~CODE
          included do
            _('a')
            ^^^^^^ #{msg}
          end
          prepended do
            self.var = _('a')
                       ^^^^^^ #{msg}
          end
          class_methods do
            _('a')
            ^^^^^^ #{msg}
          end
        CODE
      ]
    end

    with_them do
      include_examples 'offense', params[:code]
    end
  end

  describe 'ignore' do
    where(:code) do
      [
        'CONSTANT_1 = __("a")',
        'CONSTANT_2 = s__("a")',
        'CONSTANT_3 = n__("a")',
        'CONSTANT_var = _(code)',
        'CONSTANT_int = _(1)',
        'CONSTANT_none = _()',
        <<~CODE,
          class MyClass
            def self.method
              @cache ||= { hello: -> { _("hello") } }
            end
          end
        CODE
        <<~CODE,
          class MyClass
            def self.method
              @cache ||= { hello: proc { _("hello") } }
            end
          end
        CODE
        <<~CODE,
          class MyClass
            def method
              @cache ||= { hello: _("hello") }
            end
          end
        CODE
        <<~CODE,
          def method
            s_('a')
          end
        CODE
        <<~CODE,
          class MyClass
            VALID = -> {
              s_('hi')
            }
          end
        CODE
        <<~CODE,
          class MyClass
            def hello
              {
                a: _('hi')
              }
            end
          end
        CODE
        <<~CODE,
          SomeClass = Struct.new do
            def text
              _('Some translated text')
            end
          end
        CODE
        <<~CODE,
          Struct.new('SomeClass') do
            def text
              _('Some translated text')
            end
          end
        CODE
        <<~CODE,
          class MyClass
            field :foo, title: -> { _('A title') }
          end
        CODE
        <<~CODE
          included do
            put do
              _('b')
            end
          end
          class_methods do
            expose do
              _('b')
            end
          end
        CODE
      ]
    end

    with_them do
      include_examples 'no offense', params[:code]
    end
  end
end

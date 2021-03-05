# frozen_string_literal: true

require 'fast_spec_helper'

require 'rspec-parameterized'

require_relative '../../../rubocop/cop/static_translation_definition'

RSpec.describe RuboCop::Cop::StaticTranslationDefinition do
  using RSpec::Parameterized::TableSyntax

  let(:msg) do
    "The text you're translating will be already in the translated form when it's assigned to the constant. " \
    "When a users changes the locale, these texts won't be translated again. " \
    "Consider moving the translation logic to a method."
  end

  subject(:cop) { described_class.new }

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
        <<~CODE
          class MyClass
            B = [
              [
                s_("a")
                ^^^^^^^ #{msg}
              ]
            ]
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
        <<~CODE,
          class MyClass
            def self.method
              @cache ||= { hello: -> { _("hello") } }
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
        <<~CODE
          class MyClass
            def hello
              {
                a: _('hi')
              }
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

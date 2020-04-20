# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/static_translation_definition'

describe RuboCop::Cop::StaticTranslationDefinition do
  include CopHelper

  using RSpec::Parameterized::TableSyntax

  subject(:cop) { described_class.new }

  shared_examples 'offense' do |code, highlight, line|
    it 'registers an offense' do
      inspect_source(code)

      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.map(&:line)).to eq([line])
      expect(cop.highlights).to eq([highlight])
    end
  end

  shared_examples 'no offense' do |code|
    it 'does not register an offense' do
      inspect_source(code)

      expect(cop.offenses).to be_empty
    end
  end

  describe 'offenses' do
    where(:code, :highlight, :line) do
      [
        ['A = _("a")', '_("a")', 1],
        ['B = s_("b")', 's_("b")', 1],
        ['C = n_("c")', 'n_("c")', 1],
        [
          <<~CODE,
            module MyModule
              A = {
                b: {
                  c: _("a")
                }
              }
            end
          CODE
          '_("a")',
          4
        ],
        [
          <<~CODE,
            class MyClass
              B = [
                [
                  s_("a")
                ]
              ]
            end
          CODE
          's_("a")',
          4
        ]
      ]
    end

    with_them do
      include_examples 'offense', params[:code], params[:highlight], params[:line]
    end
  end

  describe 'ignore' do
    where(:code) do
      [
        'CONSTANT_1 = __("a")',
        'CONSTANT_2 = s__("a")',
        'CONSTANT_3 = n__("a")',
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

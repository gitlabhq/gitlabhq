require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/module_with_instance_variables'

describe RuboCop::Cop::Gitlab::ModuleWithInstanceVariables do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples('registering offense') do |options|
    let(:offending_lines) { options[:offending_lines] }

    it 'registers an offense when instance variable is used in a module' do
      inspect_source(source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(offending_lines.size)
        expect(cop.offenses.map(&:line)).to eq(offending_lines)
      end
    end
  end

  shared_examples('not registering offense') do
    it 'does not register offenses' do
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end

  context 'when source is a regular module' do
    it_behaves_like 'registering offense', offending_lines: [3] do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f = true
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a nested module' do
    it_behaves_like 'registering offense', offending_lines: [4] do
      let(:source) do
        <<~RUBY
          module N
            module M
              def f
                @f = true
              end
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a nested module with multiple offenses' do
    it_behaves_like 'registering offense', offending_lines: [4, 12] do
      let(:source) do
        <<~RUBY
          module N
            module M
              def f
                @f = true
              end

              def g
                true
              end

              def h
                @h = true
              end
            end
          end
        RUBY
      end
    end
  end

  context 'when source is using simple or ivar assignment' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f ||= true
            end
          end
        RUBY
      end
    end
  end

  context 'when source is using simple ivar' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def f?
              @f
            end
          end
        RUBY
      end
    end
  end

  context 'when source is defining initialize' do
    it_behaves_like 'not registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def initialize
              @a = 1
              @b = 2
            end
          end
        RUBY
      end
    end
  end

  context 'when source is using simple or ivar assignment with other ivar' do
    it_behaves_like 'registering offense', offending_lines: [3] do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f ||= g(@g)
            end
          end
        RUBY
      end
    end
  end

  context 'when source is using or ivar assignment with something else' do
    it_behaves_like 'registering offense', offending_lines: [3, 4] do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f ||= true
              @f.to_s
            end
          end
        RUBY
      end
    end
  end
end

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/module_with_instance_variables'

describe RuboCop::Cop::ModuleWithInstanceVariables do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples('registering offense') do
    it 'registers an offense when instance variable is used in a module' do
      inspect_source(cop, source)

      aggregate_failures do
        expect(cop.offenses.size).to eq(offending_lines.size)
        expect(cop.offenses.map(&:line)).to eq(offending_lines)
      end
    end
  end

  context 'when source is a regular module' do
    let(:source) do
      <<~RUBY
        module M
          def f
            @f ||= true
          end
        end
      RUBY
    end

    let(:offending_lines) { [3] }

    it_behaves_like 'registering offense'
  end

  context 'when source is a nested module' do
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

    let(:offending_lines) { [4] }

    it_behaves_like 'registering offense'
  end

  context 'when source is a nested module with multiple offenses' do
    let(:source) do
      <<~RUBY
        module N
          module M
            def f
              @f ||= true
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

    let(:offending_lines) { [4, 12] }

    it_behaves_like 'registering offense'
  end

  context 'when source is offending but it is a rails helper' do
    before do
      allow(cop).to receive(:rails_helper?).and_return(true)
    end

    it 'does not register offenses' do
      inspect_source(cop, <<~RUBY)
        module M
          def f
            @f ||= true
          end
        end
      RUBY

      expect(cop.offenses).to be_empty
    end
  end

  context 'when source is offending but it is a rails mailer' do
    before do
      allow(cop).to receive(:rails_mailer?).and_return(true)
    end

    it 'does not register offenses' do
      inspect_source(cop, <<~RUBY)
        module M
          def f
            @f = true
          end
        end
      RUBY

      expect(cop.offenses).to be_empty
    end
  end
end

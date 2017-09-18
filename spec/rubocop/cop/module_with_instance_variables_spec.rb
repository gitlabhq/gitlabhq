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

  shared_examples('not registering offense') do
    it 'does not register offenses' do
      inspect_source(cop, source)

      expect(cop.offenses).to be_empty
    end
  end

  context 'when source is a regular module' do
    let(:source) do
      <<~RUBY
        module M
          def f
            @f = true
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

    let(:offending_lines) { [4, 12] }

    it_behaves_like 'registering offense'
  end

  context 'with regular ivar assignment' do
    let(:source) do
      <<~RUBY
        module M
          def f
            @f = true
          end
        end
      RUBY
    end

    context 'when source is offending but it is a rails helper' do
      before do
        allow(cop).to receive(:rails_helper?).and_return(true)
      end

      it_behaves_like 'not registering offense'
    end

    context 'when source is offending but it is a rails mailer' do
      before do
        allow(cop).to receive(:rails_mailer?).and_return(true)
      end

      it_behaves_like 'not registering offense'
    end

    context 'when source is offending but it is a spec helper' do
      before do
        allow(cop).to receive(:spec_helper?).and_return(true)
      end

      it_behaves_like 'not registering offense'
    end
  end

  context 'when source is using simple or ivar assignment' do
    let(:source) do
      <<~RUBY
        module M
          def f
            @f ||= true
          end
        end
      RUBY
    end

    it_behaves_like 'not registering offense'
  end

  context 'when source is using simple or ivar assignment with other ivar' do
    let(:source) do
      <<~RUBY
        module M
          def f
            @f ||= g(@g)
          end
        end
      RUBY
    end

    let(:offending_lines) { [3] }

    it_behaves_like 'registering offense'
  end

  context 'when source is using or ivar assignment with something else' do
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

    let(:offending_lines) { [3, 4] }

    it_behaves_like 'registering offense'
  end
end

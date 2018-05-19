
require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/unqualified_constants'

describe RuboCop::Cop::FullyQualifiedConstants do
  include CopHelper

  subject(:cop) { described_class.new }
  
  shared_examples('registering offense') do |options|
    let(:offending_lines) { options[:offending_lines] }

    it 'registers an offense when not using a fully-qualified constant' do
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

  context 'when extending' do
    context 'with unqualified constant' do
      it_behaves_like 'registering offense', offending_lines: [2] do
        let(:source) do
          <<~RUBY
            class C
              extend Test
              def really?
                @really ||= true
              end
            end
          RUBY
        end
      end
    end

    context 'with qualified constant' do
      it_behaves_like 'not registering offense' do
        let(:source) do
          <<~RUBY
            class C
              extend Gitlab::Test
              def really?
                @really ||= ::User.find(some_var)
              end
            end
          RUBY
        end
      end
    end
  end

  context 'when including' do
    context 'with unqualified constant' do
      it_behaves_like 'registering offense', offending_lines: [2] do
        let(:source) do
          <<~RUBY
            class C
              include Test
              def really?
                @really ||= true
              end
            end
          RUBY
        end
      end
    end

    context 'with qualified constant' do
      it_behaves_like 'not registering offense' do
        let(:source) do
          <<~RUBY
            class C
              include Gitlab::Test
              def really?
                @really ||= true
              end
            end
          RUBY
        end
      end
    end
  end

  context 'when prepending' do
    context 'with unqualified constant' do
      it_behaves_like 'registering offense', offending_lines: [2] do
        let(:source) do
          <<~RUBY
            class C
              prepend Test
              def really?
                @really ||= true
              end
            end
          RUBY
        end
      end
    end

    context 'with qualified constant' do
      it_behaves_like 'not registering offense' do
        let(:source) do
          <<~RUBY
            class C
              prepend Another::Test
              def really?
                @really ||= true
              end
            end
          RUBY
        end
      end
    end
  end

  context 'when sending' do
    context 'with qualified constant' do
      it_behaves_like 'registering offense', offending_lines: [3, 4] do
        let(:source) do
          <<~RUBY
            class C
              def really?
                @really ||= User.find(1)
                @other = User.find(2)
              end
            end
          RUBY
        end
      end
    end

    context 'with unqualified constant' do
      it_behaves_like 'not registering offense' do
        let(:source) do
          <<~RUBY
            class C
              def really?
                @really ||= ::User.find(1)
              end
            end
          RUBY
        end
      end
    end
  end
end

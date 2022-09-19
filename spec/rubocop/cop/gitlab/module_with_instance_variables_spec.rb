# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/module_with_instance_variables'

RSpec.describe RuboCop::Cop::Gitlab::ModuleWithInstanceVariables do
  let(:msg) { "Do not use instance variables in a module. [...]" }

  shared_examples('registering offense') do
    it 'registers an offense when instance variable is used in a module' do
      expect_offense(source)
    end
  end

  shared_examples('not registering offense') do
    it 'does not register offenses' do
      expect_no_offenses(source)
    end
  end

  context 'when source is a regular module' do
    it_behaves_like 'registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f = true
              ^^^^^^^^^ #{msg}
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a nested module' do
    it_behaves_like 'registering offense' do
      let(:source) do
        <<~RUBY
          module N
            module M
              def f
                @f = true
                ^^^^^^^^^ #{msg}
              end
            end
          end
        RUBY
      end
    end
  end

  context 'when source is a nested module with multiple offenses' do
    it_behaves_like 'registering offense' do
      let(:source) do
        <<~RUBY
          module N
            module M
              def f
                @f = true
                ^^^^^^^^^ #{msg}
              end

              def g
                true
              end

              def h
                @h = true
                ^^^^^^^^^ #{msg}
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
    it_behaves_like 'registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f ||= g(@g)
                       ^^ #{msg}
            end
          end
        RUBY
      end
    end
  end

  context 'when source is using or ivar assignment with something else' do
    it_behaves_like 'registering offense' do
      let(:source) do
        <<~RUBY
          module M
            def f
              @f ||= true
              ^^ #{msg}
              @f.to_s
              ^^ #{msg}
            end
          end
        RUBY
      end
    end
  end
end

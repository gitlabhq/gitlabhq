# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/httparty'

RSpec.describe RuboCop::Cop::Gitlab::HTTParty do # rubocop:disable RSpec/SpecFilePathFormat
  shared_examples('registering include offense') do
    it 'registers an offense when the class includes HTTParty' do
      expect_offense(source)
    end
  end

  shared_examples('registering call offense') do
    it 'registers an offense when the class calls HTTParty' do
      expect_offense(source)
    end
  end

  context 'when source is a regular module' do
    it_behaves_like 'registering include offense' do
      let(:source) do
        <<~RUBY
          module M
            include HTTParty
            ^^^^^^^^^^^^^^^^ Avoid including `HTTParty` directly. [...]
          end
        RUBY
      end
    end
  end

  context 'when source is a regular class' do
    it_behaves_like 'registering include offense' do
      let(:source) do
        <<~RUBY
          class Foo
            include HTTParty
            ^^^^^^^^^^^^^^^^ Avoid including `HTTParty` directly. [...]
          end
        RUBY
      end
    end
  end

  context 'when HTTParty is called' do
    it_behaves_like 'registering call offense' do
      let(:source) do
        <<~RUBY
          class Foo
            def bar
              HTTParty.get('http://example.com')
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `HTTParty` directly. [...]
            end
          end
        RUBY
      end
    end
  end
end

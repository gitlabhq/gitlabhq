# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/worker'

RSpec.describe RuboCop::Cop::CodeReuse::Worker do
  it 'flags the use of a worker in a controller' do
    allow(cop)
      .to receive(:in_controller?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooController
        def index
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a controller.
        end
      end
    RUBY
  end

  it 'flags the use of a worker in an API' do
    allow(cop)
      .to receive(:in_api?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class Foo < Grape::API::Instance
        resource :projects do
          get '/' do
            FooWorker.perform_async
            ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in an API endpoint.
          end
        end
      end
    RUBY
  end

  it 'flags the use of a worker in GraphQL' do
    allow(cop)
      .to receive(:in_graphql?)
      .and_return(true)

    expect_offense(<<~RUBY)
      module Mutations
        class Foo < BaseMutation
          def resolve
            FooWorker.perform_async
            ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in an API endpoint.
          end
        end
      end
    RUBY
  end

  it 'flags the use of a worker in a Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooFinder
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Finder.
        end
      end
    RUBY
  end

  it 'flags the use of a worker in a Presenter' do
    allow(cop)
      .to receive(:in_presenter?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooPresenter
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Presenter.
        end
      end
    RUBY
  end

  it 'flags the use of a worker in a Serializer' do
    allow(cop)
      .to receive(:in_serializer?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooSerializer
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Serializer.
        end
      end
    RUBY
  end

  it 'flags the use of a worker in a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class User < ActiveRecord::Base
        def self.execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in model class methods.
        end
      end
    RUBY
  end
end

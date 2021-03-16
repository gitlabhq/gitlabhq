# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/worker'

RSpec.describe RuboCop::Cop::CodeReuse::Worker do
  subject(:cop) { described_class.new }

  it 'flags the use of a worker in a controller' do
    allow(cop)
      .to receive(:in_controller?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooController
        def index
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a controller.
        end
      end
    SOURCE
  end

  it 'flags the use of a worker in an API' do
    allow(cop)
      .to receive(:in_api?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class Foo < Grape::API::Instance
        resource :projects do
          get '/' do
            FooWorker.perform_async
            ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Grape API.
          end
        end
      end
    SOURCE
  end

  it 'flags the use of a worker in a Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooFinder
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Finder.
        end
      end
    SOURCE
  end

  it 'flags the use of a worker in a Presenter' do
    allow(cop)
      .to receive(:in_presenter?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooPresenter
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Presenter.
        end
      end
    SOURCE
  end

  it 'flags the use of a worker in a Serializer' do
    allow(cop)
      .to receive(:in_serializer?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooSerializer
        def execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in a Serializer.
        end
      end
    SOURCE
  end

  it 'flags the use of a worker in a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class User < ActiveRecord::Base
        def self.execute
          FooWorker.perform_async
          ^^^^^^^^^^^^^^^^^^^^^^^ Workers can not be used in model class methods.
        end
      end
    SOURCE
  end
end

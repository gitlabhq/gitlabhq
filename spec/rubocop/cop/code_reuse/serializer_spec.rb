# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/serializer'

RSpec.describe RuboCop::Cop::CodeReuse::Serializer do
  it 'flags the use of a Serializer in a Service class' do
    allow(cop)
      .to receive(:in_service_class?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooService
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Service class.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooFinder
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Finder.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a Presenter' do
    allow(cop)
      .to receive(:in_presenter?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooPresenter
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Presenter.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a Serializer' do
    allow(cop)
      .to receive(:in_serializer?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooSerializer
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Serializer.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a model instance method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class User < ActiveRecord::Base
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a model.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class User < ActiveRecord::Base
        def self.execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a model.
        end
      end
    RUBY
  end

  it 'flags the use of a Serializer in a worker' do
    allow(cop)
      .to receive(:in_worker?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooWorker
        def perform
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a worker.
        end
      end
    RUBY
  end
end

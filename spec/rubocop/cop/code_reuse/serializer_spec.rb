# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/serializer'

RSpec.describe RuboCop::Cop::CodeReuse::Serializer do
  subject(:cop) { described_class.new }

  it 'flags the use of a Serializer in a Service class' do
    allow(cop)
      .to receive(:in_service_class?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooService
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Service class.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooFinder
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Finder.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a Presenter' do
    allow(cop)
      .to receive(:in_presenter?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooPresenter
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Presenter.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a Serializer' do
    allow(cop)
      .to receive(:in_serializer?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooSerializer
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a Serializer.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a model instance method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class User < ActiveRecord::Base
        def execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a model.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class User < ActiveRecord::Base
        def self.execute
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a model.
        end
      end
    SOURCE
  end

  it 'flags the use of a Serializer in a worker' do
    allow(cop)
      .to receive(:in_worker?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooWorker
        def perform
          FooSerializer.new.execute
          ^^^^^^^^^^^^^^^^^ Serializers can not be used in a worker.
        end
      end
    SOURCE
  end
end

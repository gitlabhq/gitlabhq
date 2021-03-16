# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/service_class'

RSpec.describe RuboCop::Cop::CodeReuse::ServiceClass do
  subject(:cop) { described_class.new }

  it 'flags the use of a Service class in a Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooFinder
        def execute
          FooService.new.execute
          ^^^^^^^^^^^^^^ Service classes can not be used in a Finder.
        end
      end
    SOURCE
  end

  it 'flags the use of a Service class in a Presenter' do
    allow(cop)
      .to receive(:in_presenter?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooPresenter
        def execute
          FooService.new.execute
          ^^^^^^^^^^^^^^ Service classes can not be used in a Presenter.
        end
      end
    SOURCE
  end

  it 'flags the use of a Service class in a Serializer' do
    allow(cop)
      .to receive(:in_serializer?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooSerializer
        def execute
          FooService.new.execute
          ^^^^^^^^^^^^^^ Service classes can not be used in a Serializer.
        end
      end
    SOURCE
  end

  it 'flags the use of a Service class in a model' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class User < ActiveRecord::Model
        class << self
          def first
            FooService.new.execute
            ^^^^^^^^^^^^^^ Service classes can not be used in a model.
          end
        end

        def second
          FooService.new.execute
          ^^^^^^^^^^^^^^ Service classes can not be used in a model.
        end
      end
    SOURCE
  end

  it 'does not flag the use of a Service class in a regular class' do
    expect_no_offenses(<<~SOURCE)
      class Foo
        def execute
          FooService.new.execute
        end
      end
    SOURCE
  end
end

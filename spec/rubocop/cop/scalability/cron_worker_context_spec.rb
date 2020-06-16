# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/scalability/cron_worker_context'

describe RuboCop::Cop::Scalability::CronWorkerContext, type: :rubocop do
  include CopHelper
  include ExpectOffense

  subject(:cop) { described_class.new }

  it 'adds an offense when including CronjobQueue' do
    inspect_source(<<~CODE)
      class SomeWorker
        include CronjobQueue
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not add offenses for other workers' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
      end
    CODE
  end

  it 'does not add an offense when the class defines a context' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        include CronjobQueue

        with_context user: 'bla'
      end
    CODE
  end

  it 'does not add an offense when the worker calls `with_context`' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        include CronjobQueue

        def perform
          with_context(user: 'bla') do
            # more work
          end
        end
      end
    CODE
  end

  it 'does not add an offense when the worker calls `bulk_perform_async_with_contexts`' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        include CronjobQueue

        def perform
          SomeOtherWorker.bulk_perform_async_with_contexts(things,
                                                           arguments_proc: -> (thing) { thing.id },
                                                           context_proc: -> (thing) { { project: thing.project } })
        end
      end
    CODE
  end

  it 'does not add an offense when the worker calls `bulk_perform_in_with_contexts`' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        include CronjobQueue

        def perform
          SomeOtherWorker.bulk_perform_in_with_contexts(10.minutes, things,
                                                        arguments_proc: -> (thing) { thing.id },
                                                        context_proc: -> (thing) { { project: thing.project } })
        end
      end
    CODE
  end
end

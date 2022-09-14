# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/scalability/cron_worker_context'

RSpec.describe RuboCop::Cop::Scalability::CronWorkerContext do
  it 'adds an offense when including CronjobQueue' do
    expect_offense(<<~CODE)
      class SomeWorker
        include CronjobQueue
                ^^^^^^^^^^^^ Manually define an ApplicationContext for cronjob-workers.[...]
      end
    CODE
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

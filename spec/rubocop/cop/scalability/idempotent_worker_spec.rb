# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/scalability/idempotent_worker'

RSpec.describe RuboCop::Cop::Scalability::IdempotentWorker do
  before do
    allow(cop)
      .to receive(:in_worker?)
      .and_return(true)
  end

  it 'adds an offense when not defining idempotent method' do
    expect_offense(<<~CODE)
      class SomeWorker
      ^^^^^^^^^^^^^^^^ Avoid adding not idempotent workers.[...]
      end
    CODE
  end

  it 'adds an offense when not defining idempotent method' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        idempotent!
      end
    CODE
  end
end

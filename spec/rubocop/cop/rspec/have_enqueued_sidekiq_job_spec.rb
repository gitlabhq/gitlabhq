# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/rspec/have_enqueued_sidekiq_job'

RSpec.describe RuboCop::Cop::RSpec::HaveEnqueuedSidekiqJob do
  let(:source_file) { 'spec/foo_spec.rb' }

  subject(:cop) { described_class.new }

  shared_examples 'cop' do |good:, bad:|
    context "using #{bad} call" do
      it 'registers an offense', :aggregate_failures do
        expect_offense(<<~CODE, node: bad)
          %{node}
          ^{node} Do not use `receive(:perform_async)` to check a job has been enqueued, use `have_enqueued_sidekiq_job` instead.
        CODE
      end
    end

    context "using #{good} call" do
      it 'does not register an offense' do
        expect_no_offenses(good)
      end
    end
  end

  it_behaves_like 'cop',
    bad: 'expect(Worker).to receive(:perform_async)',
    good: 'expect(Worker).to have_enqueued_sidekiq_job'

  include_examples 'cop',
    bad: 'expect(Worker).not_to receive(:perform_async)',
    good: 'expect(Worker).not_to have_enqueued_sidekiq_job'

  include_examples 'cop',
    bad: 'expect(Worker).to_not receive(:perform_async)',
    good: 'expect(Worker).to_not have_enqueued_sidekiq_job'

  include_examples 'cop',
    bad: 'expect(Worker).to receive(:perform_async).with(1)',
    good: 'expect(Worker).to have_enqueued_sidekiq_job(1)'

  include_examples 'cop',
    bad: 'expect(Worker).to receive(:perform_async).with(1).once',
    good: 'expect(Worker).to have_enqueued_sidekiq_job(1)'

  include_examples 'cop',
    bad: 'expect(any_variable_or_method).to receive(:perform_async).with(1)',
    good: 'expect(any_variable_or_method).to have_enqueued_sidekiq_job(1)'
end

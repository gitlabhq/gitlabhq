# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/stub_env'

# NOTE: Under the context of fast_spec_helper, when we `require 'gitlab'`
# we do not load the Gitlab client, but our own Gitlab module.
# Keep this in mind and just stub anything which might touch it!
require_relative '../../../scripts/setup/generate-as-if-foss-env'

RSpec.describe GenerateAsIfFossEnv, feature_category: :tooling do
  include StubENV

  subject(:generate) { described_class.new }

  before do
    stub_env(RUBY_VERSION: '3.1')
  end

  shared_context 'when there are all jobs' do
    let(:jobs) do
      [
        'rspec fast_spec_helper',
        'rspec unit',
        'rspec integration',
        'rspec system',
        'rspec migration',
        'rspec background-migration',
        'jest',
        'jest-integration'
      ]
    end

    before do
      messages = receive_message_chain(:client, :pipeline_jobs, :auto_paginate)

      yield_jobs = jobs.inject(messages) do |stub, job|
        stub.and_yield(double(name: job)) # rubocop:disable RSpec/VerifiedDoubles -- As explained at the top of this file, we do not load the Gitlab client
      end

      allow(Gitlab).to yield_jobs
    end
  end

  describe '#variables' do
    include_context 'when there are all jobs'

    it 'returns correct variables' do
      expect(generate.variables).to eq({
        START_AS_IF_FOSS: 'true',
        RUBY_VERSION: ENV['RUBY_VERSION'],
        ENABLE_RSPEC: 'true',
        ENABLE_RSPEC_FAST_SPEC_HELPER: 'true',
        ENABLE_RSPEC_UNIT: 'true',
        ENABLE_RSPEC_INTEGRATION: 'true',
        ENABLE_RSPEC_SYSTEM: 'true',
        ENABLE_RSPEC_MIGRATION: 'true',
        ENABLE_RSPEC_BACKGROUND_MIGRATION: 'true',
        ENABLE_JEST: 'true',
        ENABLE_JEST_INTEGRATION: 'true'
      })
    end
  end

  describe '#display' do
    include_context 'when there are all jobs'

    it 'puts correct variables' do
      expect { generate.display }.to output(<<~ENV).to_stdout
        START_AS_IF_FOSS=true
        RUBY_VERSION=#{ENV['RUBY_VERSION']}
        ENABLE_RSPEC=true
        ENABLE_RSPEC_FAST_SPEC_HELPER=true
        ENABLE_RSPEC_UNIT=true
        ENABLE_RSPEC_INTEGRATION=true
        ENABLE_RSPEC_SYSTEM=true
        ENABLE_RSPEC_MIGRATION=true
        ENABLE_RSPEC_BACKGROUND_MIGRATION=true
        ENABLE_JEST=true
        ENABLE_JEST_INTEGRATION=true
      ENV
    end
  end
end

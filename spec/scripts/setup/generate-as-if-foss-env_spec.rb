# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/stub_env'

# NOTE: Under the context of fast_spec_helper, when we `require 'gitlab'`
# we do not load the Gitlab client, but our own Gitlab module.
# Keep this in mind and just stub anything which might touch it!
require_relative '../../../scripts/setup/generate-as-if-foss-env'

RSpec.describe GenerateAsIfFossEnv, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- We use dashes in scripts
  include StubENV

  subject(:generate) { described_class.new }

  before do
    stub_env(
      'RUBY_VERSION' => '3.1',
      'CI_MERGE_REQUEST_PROJECT_PATH' => 'fake-mr-project-path',
      'CI_MERGE_REQUEST_IID' => 'fake-mr-iid')
  end

  shared_context 'when there are all jobs' do
    let(:jobs) do
      [
        'rspec fast_spec_helper',
        'rspec unit pg14 praefect 1/5',
        'rspec unit pg14 single-db 2/5',
        'rspec unit pg14 single-db-ci-connection 3/5',
        'rspec unit pg14 single-redis 4/5',
        'rspec unit pg14 5/5',
        'rspec integration pg14',
        'rspec system pg14',
        'rspec migration pg14',
        'rspec background_migration pg14',
        'rspec-all frontend_fixture',
        'build-assets-image',
        'build-qa-image',
        'compile-production-assets',
        'compile-storybook',
        'compile-test-assets',
        'cache-assets:test',
        'detect-tests',
        'eslint',
        'generate-apollo-graphql-schema',
        'graphql-schema-dump',
        'jest 1/5',
        'jest-integration',
        'jest predictive 1/5',
        'rubocop',
        'qa:internal',
        'qa:selectors',
        'static-analysis'
      ]
    end

    let(:bridges) do
      [
        'rspec-predictive:pipeline-generate',
        'rspec:predictive:trigger',
        'rspec:predictive:trigger single-db',
        'rspec:predictive:trigger single-db-ci-connection'
      ]
    end

    # rubocop:disable RSpec/VerifiedDoubles -- As explained at the top of this file, we do not load the Gitlab client
    before do
      client = double
      allow(Gitlab).to receive(:client).and_return(client)

      allow(client).to yield_jobs(:pipeline_jobs, jobs)
      allow(client).to yield_jobs(:pipeline_bridges, bridges)
    end

    def yield_jobs(api_method, jobs)
      messages = receive_message_chain(api_method, :auto_paginate)

      jobs.inject(messages) do |stub, job_name|
        stub.and_yield(double(name: job_name))
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end

  describe '#variables' do
    include_context 'when there are all jobs'

    it 'returns correct variables' do
      expect(generate.variables).to eq({
        START_AS_IF_FOSS: 'true',
        RUBY_VERSION: ENV['RUBY_VERSION'],
        FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH: ENV['CI_MERGE_REQUEST_PROJECT_PATH'],
        FIND_CHANGES_MERGE_REQUEST_IID: ENV['CI_MERGE_REQUEST_IID'],
        ENABLE_RSPEC: 'true',
        ENABLE_RSPEC_FAST_SPEC_HELPER: 'true',
        ENABLE_RSPEC_UNIT: 'true',
        ENABLE_RSPEC_PRAEFECT: 'true',
        ENABLE_RSPEC_SINGLE_DB: 'true',
        ENABLE_RSPEC_SINGLE_DB_CI_CONNECTION: 'true',
        ENABLE_RSPEC_SINGLE_REDIS: 'true',
        ENABLE_RSPEC_INTEGRATION: 'true',
        ENABLE_RSPEC_SYSTEM: 'true',
        ENABLE_RSPEC_MIGRATION: 'true',
        ENABLE_RSPEC_BACKGROUND_MIGRATION: 'true',
        ENABLE_RSPEC_FRONTEND_FIXTURE: 'true',
        ENABLE_BUILD_ASSETS_IMAGE: 'true',
        ENABLE_BUILD_QA_IMAGE: 'true',
        ENABLE_COMPILE_PRODUCTION_ASSETS: 'true',
        ENABLE_COMPILE_STORYBOOK: 'true',
        ENABLE_COMPILE_TEST_ASSETS: 'true',
        ENABLE_CACHE_ASSETS: 'true',
        ENABLE_DETECT_TESTS: 'true',
        ENABLE_ESLINT: 'true',
        ENABLE_GENERATE_APOLLO_GRAPHQL_SCHEMA: 'true',
        ENABLE_GRAPHQL_SCHEMA_DUMP: 'true',
        ENABLE_JEST: 'true',
        ENABLE_JEST_INTEGRATION: 'true',
        ENABLE_JEST_PREDICTIVE: 'true',
        ENABLE_RUBOCOP: 'true',
        ENABLE_QA_INTERNAL: 'true',
        ENABLE_QA_SELECTORS: 'true',
        ENABLE_STATIC_ANALYSIS: 'true',
        ENABLE_RSPEC_PREDICTIVE_PIPELINE_GENERATE: 'true',
        ENABLE_RSPEC_PREDICTIVE_TRIGGER: 'true',
        ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB: 'true',
        ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB_CI_CONNECTION: 'true'
      })
    end

    context 'when there are only predictive frontend jobs' do
      let(:jobs) do
        [
          'jest-integration',
          'jest predictive 1/5',
          'jest-with-fixtures predictive 1/2'
        ]
      end

      let(:bridges) { [] }

      it 'returns correct variables without ENABLE_JEST' do
        expect(generate.variables).to eq({
          START_AS_IF_FOSS: 'true',
          RUBY_VERSION: ENV['RUBY_VERSION'],
          FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH: ENV['CI_MERGE_REQUEST_PROJECT_PATH'],
          FIND_CHANGES_MERGE_REQUEST_IID: ENV['CI_MERGE_REQUEST_IID'],
          ENABLE_JEST_INTEGRATION: 'true',
          ENABLE_JEST_PREDICTIVE: 'true'
        })
      end
    end
  end

  describe '#display' do
    include_context 'when there are all jobs'

    it 'puts correct variables' do
      expect { generate.display }.to output(<<~ENV).to_stdout
        START_AS_IF_FOSS=true
        RUBY_VERSION=#{ENV['RUBY_VERSION']}
        FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH=#{ENV['CI_MERGE_REQUEST_PROJECT_PATH']}
        FIND_CHANGES_MERGE_REQUEST_IID=#{ENV['CI_MERGE_REQUEST_IID']}
        ENABLE_RSPEC=true
        ENABLE_RSPEC_FAST_SPEC_HELPER=true
        ENABLE_RSPEC_UNIT=true
        ENABLE_RSPEC_PRAEFECT=true
        ENABLE_RSPEC_SINGLE_DB=true
        ENABLE_RSPEC_SINGLE_DB_CI_CONNECTION=true
        ENABLE_RSPEC_SINGLE_REDIS=true
        ENABLE_RSPEC_INTEGRATION=true
        ENABLE_RSPEC_SYSTEM=true
        ENABLE_RSPEC_MIGRATION=true
        ENABLE_RSPEC_BACKGROUND_MIGRATION=true
        ENABLE_RSPEC_FRONTEND_FIXTURE=true
        ENABLE_BUILD_ASSETS_IMAGE=true
        ENABLE_BUILD_QA_IMAGE=true
        ENABLE_COMPILE_PRODUCTION_ASSETS=true
        ENABLE_COMPILE_STORYBOOK=true
        ENABLE_COMPILE_TEST_ASSETS=true
        ENABLE_CACHE_ASSETS=true
        ENABLE_DETECT_TESTS=true
        ENABLE_ESLINT=true
        ENABLE_GENERATE_APOLLO_GRAPHQL_SCHEMA=true
        ENABLE_GRAPHQL_SCHEMA_DUMP=true
        ENABLE_JEST=true
        ENABLE_JEST_INTEGRATION=true
        ENABLE_JEST_PREDICTIVE=true
        ENABLE_RUBOCOP=true
        ENABLE_QA_INTERNAL=true
        ENABLE_QA_SELECTORS=true
        ENABLE_STATIC_ANALYSIS=true
        ENABLE_RSPEC_PREDICTIVE_PIPELINE_GENERATE=true
        ENABLE_RSPEC_PREDICTIVE_TRIGGER=true
        ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB=true
        ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB_CI_CONNECTION=true
      ENV
    end
  end

  describe '.gitlab/ci/rules.gitlab-ci.yml' do
    include_context 'when there are all jobs'

    let(:rules_yaml) do
      File.read(File.expand_path('../../../.gitlab/ci/rules.gitlab-ci.yml', __dir__))
    end

    it 'uses all the ENABLE variables' do
      generate.variables.each_key do |variable|
        next unless variable.start_with?('ENABLE_')

        expect(rules_yaml).to include("- if: '$#{variable} == \"true\"'")
      end
    end
  end

  describe '.gitlab/ci/as-if-foss.gitlab-ci.yml' do
    include_context 'when there are all jobs'

    let(:ci_yaml) do
      File.read(File.expand_path('../../../.gitlab/ci/as-if-foss.gitlab-ci.yml', __dir__))
    end

    it 'uses all the ENABLE variables' do
      generate.variables.each_key do |variable|
        next unless variable.start_with?('ENABLE_')

        expect(ci_yaml).to include("#{variable}: $#{variable}")
      end
    end
  end
end

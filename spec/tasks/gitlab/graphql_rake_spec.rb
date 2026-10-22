# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:graphql docs rake tasks', :silence_stdout, feature_category: :api do
  include RakeHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/graphql'
    Rake.application.rake_require 'tasks/gitlab/graphql_introspection'
    Rake::Task.define_task(:environment)

    # These prerequisites redefine Gitlab.com? and Feature.enabled? with `def`, which leaks
    # into every later example in the process. Rake runs prerequisites through `execute`,
    # not `invoke`, so `execute` is the method to stub.
    allow(Rake::Task['gitlab:simulate_saas']).to receive(:execute)
    allow(Rake::Task['gitlab:enable_feature_flags']).to receive(:execute)
  end

  describe 'gitlab:graphql:docs:compile' do
    it 'compiles the documentation' do
      expect(Tooling::Graphql::Docs).to receive(:compile!)

      expect { run_rake_task('gitlab:graphql:docs:compile') }
        .to output(/GraphQL documentation compiled/).to_stdout
    end
  end

  describe 'gitlab:graphql:docs:check' do
    context 'when the documentation is up to date' do
      before do
        allow(Tooling::Graphql::Docs).to receive(:stale?).and_return(false)
      end

      it 'reports that the documentation is up to date' do
        expect { run_rake_task('gitlab:graphql:docs:check') }
          .to output(/GraphQL documentation is up to date/).to_stdout
      end
    end

    context 'when the documentation is stale' do
      before do
        allow(Tooling::Graphql::Docs).to receive(:stale?).and_return(true)
      end

      it 'aborts, naming the task that regenerates the documentation and how to check for drift from master' do
        expect { run_rake_task('gitlab:graphql:docs:check') }
          .to output(
            %r{
              Please\ update\ the\ documentation\ by\ running\ `bundle\ exec\ rake\ gitlab:graphql:docs:compile`
              .*
              git\ log\ --oneline\ HEAD\.\.origin/master\ --\ doc/api/graphql/reference/$
            }xm
          ).to_stdout.and raise_error(SystemExit)
      end
    end
  end

  describe 'gitlab:graphql:compile_docs (deprecated)' do
    it 'invokes gitlab:graphql:docs:compile' do
      expect(Rake::Task['gitlab:graphql:docs:compile']).to receive(:invoke)

      run_rake_task('gitlab:graphql:compile_docs')
    end
  end

  describe 'gitlab:graphql:check_docs (deprecated)' do
    it 'invokes gitlab:graphql:docs:check' do
      expect(Rake::Task['gitlab:graphql:docs:check']).to receive(:invoke)

      run_rake_task('gitlab:graphql:check_docs')
    end
  end

  describe 'gitlab:graphql:update_all' do
    it 'compiles the documentation, dumps the schema, and generates the introspection schemas' do
      expect(Rake::Task['gitlab:graphql:update_all'].prerequisite_tasks.map(&:name)).to contain_exactly(
        'gitlab:graphql:docs:compile',
        'gitlab:graphql:schema:dump',
        'gitlab:graphql:generate_all_introspection_schemas'
      )
    end
  end
end

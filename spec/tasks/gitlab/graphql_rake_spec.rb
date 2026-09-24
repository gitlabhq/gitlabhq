# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:graphql:check_docs rake task', :silence_stdout, feature_category: :api do
  include RakeHelpers

  let(:committed_docs) { File.read(Rails.root.join('doc/api/graphql/reference/_index.md')) }

  before do
    Rake.application.rake_require 'tasks/gitlab/graphql'
    Rake::Task.define_task(:environment)

    # These prerequisites redefine Gitlab.com? and Feature.enabled? with `def`, which leaks
    # into every later example in the process. Rake runs prerequisites through `execute`,
    # not `invoke`, so `execute` is the method to stub.
    allow(Rake::Task['gitlab:simulate_saas']).to receive(:execute)
    allow(Rake::Task['gitlab:enable_feature_flags']).to receive(:execute)

    # Rendering the real schema takes minutes, and the task only compares two strings.
    allow(Tooling::Graphql::DeprecatedDocs::Renderer).to receive(:new).and_return(
      instance_double(Tooling::Graphql::DeprecatedDocs::Renderer, contents: rendered_docs)
    )
  end

  context 'when the rendered docs match the committed file' do
    let(:rendered_docs) { committed_docs }

    it 'reports that the documentation is up to date' do
      expect { run_rake_task('gitlab:graphql:check_docs') }
        .to output(/GraphQL documentation is up to date/).to_stdout
    end
  end

  context 'when the rendered docs differ from the committed file' do
    let(:rendered_docs) { "#{committed_docs}\n### `Query.newField`\n" }

    it 'aborts, naming the task that regenerates the documentation' do
      expect { run_rake_task('gitlab:graphql:check_docs') }
        .to output(/Please update it by running `bundle exec rake gitlab:graphql:compile_docs`/).to_stdout
        .and raise_error(SystemExit)
    end

    it 'points at master, because the check only sees the current branch' do
      expect { run_rake_task('gitlab:graphql:check_docs') }
        .to output(
          %r{git log --oneline HEAD\.\.origin/master -- doc/api/graphql/reference/_index\.md}
        ).to_stdout.and raise_error(SystemExit)
    end
  end
end

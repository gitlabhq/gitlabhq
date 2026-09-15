# frozen_string_literal: true

require 'spec_helper'

# The gem is `require: false` in the Gemfile; the tasks load it lazily.
require 'gitlab/cells/http_router'

RSpec.describe 'gitlab:cells:routes rake tasks', feature_category: :cell do
  let(:output_path) { Rails.root.join('config/routing/gitlab_routes.json') }
  let(:snapshot) do
    instance_double(Gitlab::Cells::HttpRouter::RoutesSnapshot, write!: output_path, routes: [])
  end

  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/cells/routes'
  end

  before do
    # The tasks re-exec the process unless they detect CI's invocation context.
    # Point GITLAB_CONFIG at the canonical config so the guard returns early;
    # otherwise the exec replaces the rspec process and aborts the run.
    stub_env('GITLAB_CONFIG' => Rails.root.join('config/gitlab.yml.example').to_s)

    allow(Gitlab::Cells::HttpRouter::RoutesSnapshot).to receive(:new).and_return(snapshot)
  end

  shared_examples 'a task that refuses to run under FOSS_ONLY' do
    it 'aborts, because EE routes would be missing' do
      stub_env('FOSS_ONLY' => 'true')

      expect { rake_task }.to raise_error(SystemExit)
        .and output(/cannot run with FOSS_ONLY=true/).to_stderr
    end
  end

  describe 'gitlab:cells:routes:generate' do
    subject(:rake_task) { run_rake_task('gitlab:cells:routes:generate') }

    it_behaves_like 'a task that refuses to run under FOSS_ONLY'

    it 'writes the snapshot and reports the route count' do
      expect(snapshot).to receive(:write!).with(output_path)

      expect { rake_task }.to output(/Generated 0 routes at #{output_path}/).to_stdout
    end

    it 'passes both the Rails and the Grape route tables to the snapshot' do
      rails_spec = Rails.application.routes.routes.first.path.spec.to_s
      grape_spec = API::API.routes.first.path.to_s

      expect(Gitlab::Cells::HttpRouter::RoutesSnapshot).to receive(:new)
        .with(path_specs: include(rails_spec, grape_spec)).and_return(snapshot)

      expect { rake_task }.to output.to_stdout
    end
  end

  describe 'gitlab:cells:routes:updated_check' do
    subject(:rake_task) { run_rake_task('gitlab:cells:routes:updated_check') }

    def stub_git(diff: '', untracked: '')
      allow(Gitlab::Popen).to receive(:popen).and_return(['', 0])
      allow(Gitlab::Popen).to receive(:popen)
        .with(array_including('diff')).and_return([diff, 0])
      allow(Gitlab::Popen).to receive(:popen)
        .with(array_including('ls-files')).and_return([untracked, 0])
    end

    it_behaves_like 'a task that refuses to run under FOSS_ONLY'

    it 'regenerates the snapshot' do
      stub_git

      expect(snapshot).to receive(:write!).with(output_path)

      rake_task
    end

    context 'when the regenerated snapshot matches the committed tree' do
      before do
        stub_git
      end

      it 'does not raise' do
        expect { rake_task }.not_to raise_error
      end
    end

    context 'when regeneration produces a diff against the committed snapshot' do
      before do
        stub_git(diff: "diff --git a/config/routing/gitlab_routes.json b/config/routing/gitlab_routes.json\n+new line")
      end

      it 'raises with the regeneration instructions' do
        expect { rake_task }.to raise_error do |error|
          expect(error.message).to include('config/routing/gitlab_routes.json is out of date.')
          expect(error.message).to include('bundle exec rake gitlab:cells:routes:generate')
        end
      end

      it 'points at a rebase, since the drift may have come from master' do
        expect { rake_task }.to raise_error(%r{git rebase origin/master})
      end
    end

    context 'when the snapshot was deleted and regenerated as an untracked file' do
      before do
        stub_git(untracked: 'config/routing/gitlab_routes.json')
      end

      it 'raises with the regeneration instructions' do
        expect { rake_task }.to raise_error do |error|
          expect(error.message).to include('config/routing/gitlab_routes.json is out of date.')
          expect(error.message).to include('bundle exec rake gitlab:cells:routes:generate')
        end
      end
    end
  end
end

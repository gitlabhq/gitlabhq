# frozen_string_literal: true

require 'rake_helper'
require_relative '../../support/helpers/next_instance_of'

RSpec.describe 'gitlab:metrics_exporter:install', feature_category: :metrics do
  before do
    Rake.application.rake_require 'tasks/gitlab/metrics_exporter'
  end

  subject(:task) do
    Rake::Task['gitlab:metrics_exporter:install']
  end

  context 'when no target directory is specified' do
    it 'aborts with an error message' do
      expect do
        expect { task.execute }.to output(/Please specify the directory/).to_stdout
      end.to raise_error(SystemExit)
    end
  end

  context 'when target directory is specified' do
    let(:args) { Rake::TaskArguments.new(%w[dir], %w[path/to/exporter]) }
    let(:context) { TOPLEVEL_BINDING.eval('self') }
    let(:expected_clone_params) do
      {
        repo: 'https://gitlab.com/gitlab-org/gitlab-metrics-exporter.git',
        version: an_instance_of(String),
        target_dir: 'path/to/exporter'
      }
    end

    context 'when dependencies are missing' do
      it 'aborts with an error message' do
        expect(Gitlab::Utils).to receive(:which).with('gmake').ordered
        expect(Gitlab::Utils).to receive(:which).with('make').ordered

        expect do
          expect { task.execute(args) }.to output(/Couldn't find a 'make' binary/).to_stdout
        end.to raise_error(SystemExit)
      end
    end

    it 'installs the exporter with gmake' do
      expect(Gitlab::Utils).to receive(:which).with('gmake').and_return('path/to/gmake').ordered
      expect(context).to receive(:checkout_or_clone_version).with(hash_including(expected_clone_params)).ordered
      expect(Dir).to receive(:chdir).with('path/to/exporter').and_yield.ordered
      expect(context).to receive(:run_command!).with(['path/to/gmake']).ordered

      task.execute(args)
    end

    it 'installs the exporter with make' do
      expect(Gitlab::Utils).to receive(:which).with('gmake').ordered
      expect(Gitlab::Utils).to receive(:which).with('make').and_return('path/to/make').ordered
      expect(context).to receive(:checkout_or_clone_version).with(hash_including(expected_clone_params)).ordered
      expect(Dir).to receive(:chdir).with('path/to/exporter').and_yield.ordered
      expect(context).to receive(:run_command!).with(['path/to/make']).ordered

      task.execute(args)
    end

    context 'when overriding version via environment variable' do
      before do
        stub_env('GITLAB_METRICS_EXPORTER_VERSION', '1.0')
      end

      it 'clones from repository with that version instead' do
        expect(Gitlab::Utils).to receive(:which).with('gmake').and_return('path/to/gmake').ordered
        expect(context).to receive(:checkout_or_clone_version).with(
          hash_including(expected_clone_params.merge(version: '1.0'))
        ).ordered
        expect(Dir).to receive(:chdir).with('path/to/exporter').and_yield.ordered
        expect(context).to receive(:run_command!).with(['path/to/gmake']).ordered

        task.execute(args)
      end
    end
  end
end

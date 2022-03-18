# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'dev rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/setup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/dev'
  end

  describe 'setup' do
    subject(:setup_task) { run_rake_task('dev:setup') }

    let(:connections) { Gitlab::Database.database_base_models.values.map(&:connection) }

    it 'sets up the development environment', :aggregate_failures do
      expect(Rake::Task['gitlab:setup']).to receive(:invoke)

      expect(connections).to all(receive(:execute).with('ANALYZE'))

      expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)

      setup_task
    end
  end

  describe 'load' do
    subject(:load_task) { run_rake_task('dev:load') }

    it 'eager loads the application', :aggregate_failures do
      expect(Rails.configuration).to receive(:eager_load=).with(true)
      expect(Rails.application).to receive(:eager_load!)

      load_task
    end
  end
end

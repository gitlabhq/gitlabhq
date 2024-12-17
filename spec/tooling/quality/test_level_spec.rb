# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../tooling/quality/test_level'

RSpec.describe Quality::TestLevel, feature_category: :tooling do
  describe 'TEST_LEVEL_FOLDERS constant' do
    it 'ensures all directories it refers to exists', :aggregate_failures do
      ee_only_directories = %w[
        lib/ee/gitlab/background_migration
        elastic
        elastic_integration
        replicators
      ]

      described_class::TEST_LEVEL_FOLDERS.values.flatten.each do |dir|
        next if ee_only_directories.include?(dir) && !Gitlab.ee?

        spec_directory = if ee_only_directories.include?(dir)
                           File.join('ee', 'spec', dir)
                         else
                           File.join('spec', dir)
                         end

        expect(File.exist?(spec_directory)).to eq(true), "#{spec_directory} does not exist!"
      end
    end
  end

  describe '#pattern' do
    context 'when level is all' do
      it 'returns a pattern' do
        expect(subject.pattern(:all))
        .to eq("spec/**{,/**/}*_spec.rb")
      end
    end

    context 'when level is frontend_fixture' do
      it 'returns a pattern' do
        expect(subject.pattern(:frontend_fixture))
          .to eq("spec/{frontend/fixtures}{,/**/}*.rb")
      end
    end

    context 'when level is unit' do
      it 'returns a pattern' do
        expect(subject.pattern(:unit))
          .to eq("spec/{bin,channels,components,config,contracts,db,dependencies,elastic,elastic_integration,experiments,facades,factories,finders,frontend,graphql,haml_lint,helpers,initializers,keeps,lib,metrics_server,models,policies,presenters,rack_servers,replicators,routing,rubocop,scripts,serializers,services,sidekiq,sidekiq_cluster,spam,support_specs,tasks,uploaders,validators,views,workers,tooling,dot_gitlab_ci}{,/**/}*_spec.rb")
      end
    end

    context 'when level is migration' do
      it 'returns a pattern' do
        expect(subject.pattern(:migration))
          .to eq("spec/{migrations}{,/**/}*_spec.rb")
      end
    end

    context 'when level is background_migration' do
      it 'returns a pattern' do
        expect(subject.pattern(:background_migration))
          .to eq("spec/{lib/gitlab/background_migration,lib/ee/gitlab/background_migration}{,/**/}*_spec.rb")
      end
    end

    context 'when level is integration' do
      it 'returns a pattern' do
        expect(subject.pattern(:integration))
          .to eq("spec/{commands,controllers,mailers,requests}{,/**/}*_spec.rb")
      end
    end

    context 'when level is system' do
      it 'returns a pattern' do
        expect(subject.pattern(:system))
          .to eq("spec/{features}{,/**/}*_spec.rb")
      end
    end

    context 'with a prefix' do
      it 'returns a pattern' do
        expect(described_class.new('ee/').pattern(:system))
          .to eq("{ee/}spec/{features}{,/**/}*_spec.rb")
      end
    end

    context 'with several prefixes' do
      it 'returns a pattern' do
        expect(described_class.new(['', 'ee/', 'jh/']).pattern(:system))
          .to eq("{,ee/,jh/}spec/{features}{,/**/}*_spec.rb")
      end
    end

    describe 'performance' do
      it 'memoizes the pattern for a given level' do
        expect(subject.pattern(:system).object_id).to eq(subject.pattern(:system).object_id)
      end

      it 'freezes the pattern for a given level' do
        expect(subject.pattern(:system)).to be_frozen
      end
    end
  end

  describe '#regexp' do
    context 'when level is all' do
      it 'returns a regexp' do
        expect(subject.regexp(:all))
        .to eq(%r{spec/})
      end
    end

    context 'when level is frontend_fixture' do
      it 'returns a regexp' do
        expect(subject.regexp(:frontend_fixture))
          .to eq(%r{spec/(frontend/fixtures)/})
      end
    end

    context 'when level is unit' do
      it 'returns a regexp' do
        expect(subject.regexp(:unit))
          .to eq(%r{spec/(bin|channels|components|config|contracts|db|dependencies|elastic|elastic_integration|experiments|facades|factories|finders|frontend|graphql|haml_lint|helpers|initializers|keeps|lib|metrics_server|models|policies|presenters|rack_servers|replicators|routing|rubocop|scripts|serializers|services|sidekiq|sidekiq_cluster|spam|support_specs|tasks|uploaders|validators|views|workers|tooling|dot_gitlab_ci)/})
      end
    end

    context 'when level is migration' do
      it 'returns a regexp' do
        expect(subject.regexp(:migration))
          .to eq(%r{spec/(migrations)/})
      end
    end

    context 'when level is background_migration' do
      it 'returns a regexp' do
        expect(subject.regexp(:background_migration))
          .to eq(%r{spec/(lib/gitlab/background_migration|lib/ee/gitlab/background_migration)/})
      end
    end

    context 'when level is integration' do
      it 'returns a regexp' do
        expect(subject.regexp(:integration))
          .to eq(%r{spec/(commands|controllers|mailers|requests)/})
      end
    end

    context 'when level is system' do
      it 'returns a regexp' do
        expect(subject.regexp(:system))
          .to eq(%r{spec/(features)/})
      end
    end

    context 'with a prefix' do
      it 'returns a regexp' do
        expect(described_class.new('ee/').regexp(:system))
          .to eq(%r{(ee/)spec/(features)/})
      end
    end

    context 'with several prefixes' do
      it 'returns a regexp' do
        expect(described_class.new(['', 'ee/', 'jh/']).regexp(:system))
          .to eq(%r{(|ee/|jh/)spec/(features)/})
      end
    end

    context 'when start_with == true' do
      it 'returns a regexp' do
        expect(described_class.new(['ee/']).regexp(:system, true))
          .to eq(%r{^(ee/)spec/(features)/})
      end
    end

    describe 'performance' do
      it 'memoizes the regexp for a given level' do
        expect(subject.regexp(:system).object_id).to eq(subject.regexp(:system).object_id)
      end

      it 'freezes the regexp for a given level' do
        expect(subject.regexp(:system)).to be_frozen
      end
    end
  end

  describe '#level_for' do
    it 'returns the correct level for a unit test' do
      expect(subject.level_for('spec/models/abuse_report_spec.rb')).to eq(:unit)
    end

    it 'returns the correct level for a frontend fixture test' do
      expect(subject.level_for('spec/frontend/fixtures/pipelines.rb')).to eq(:frontend_fixture)
    end

    it 'returns the correct level for a tooling test' do
      expect(subject.level_for('spec/tooling/lib/tooling/test_file_finder_spec.rb')).to eq(:unit)
    end

    it 'returns the correct level for a migration test' do
      expect(subject.level_for('spec/migrations/add_default_and_free_plans_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for a background migration test' do
      expect(subject.level_for('spec/lib/gitlab/background_migration/archive_legacy_traces_spec.rb')).to eq(:background_migration)
    end

    it 'returns the correct level for an EE file without passing a prefix' do
      expect(subject.level_for('ee/spec/migrations/geo/migrate_ci_job_artifacts_to_separate_registry_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for a geo migration test' do
      expect(described_class.new('ee/').level_for('ee/spec/migrations/geo/migrate_ci_job_artifacts_to_separate_registry_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for a EE-namespaced background migration test' do
      expect(described_class.new('ee/').level_for('ee/spec/lib/ee/gitlab/background_migration/prune_orphaned_geo_events_spec.rb')).to eq(:background_migration)
    end

    it 'returns the correct level for an integration test' do
      expect(subject.level_for('spec/mailers/abuse_report_mailer_spec.rb')).to eq(:integration)
    end

    it 'returns the correct level for an integration test in a subfolder' do
      expect(subject.level_for('spec/commands/sidekiq_cluster/cli.rb')).to eq(:integration)
    end

    it 'returns the correct level for a system test' do
      expect(subject.level_for('spec/features/abuse_report_spec.rb')).to eq(:system)
    end

    it 'returns the correct level for a keep test' do
      expect(subject.level_for('spec/keeps/helpers/postgres_ai_spec.rb')).to eq(:unit)
    end

    it 'raises an error for an unknown level' do
      expect { subject.level_for('spec/unknown/foo_spec.rb') }
        .to raise_error(described_class::UnknownTestLevelError,
          %r{Test level for spec/unknown/foo_spec.rb couldn't be set. Please rename the file properly or change the test level detection regexes in .+/tooling/quality/test_level.rb.})
    end

    it 'ensures all spec/ folders are covered by a test level' do
      Dir['{,ee/}spec/**/*/'].each do |path|
        next if %r{\A(ee/)?spec/(benchmarks|docs_screenshots|fixtures|frontend_integration|support)/}.match?(path)

        expect { subject.level_for(path) }.not_to raise_error
      end
    end
  end
end

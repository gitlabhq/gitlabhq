# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Quality::TestLevel do
  describe '#pattern' do
    context 'when level is all' do
      it 'returns a pattern' do
        expect(subject.pattern(:all))
        .to eq("spec/**{,/**/}*_spec.rb")
      end
    end

    context 'when level is geo' do
      it 'returns a pattern' do
        expect(subject.pattern(:geo))
        .to eq("spec/**{,/**/}*_spec.rb")
      end
    end

    context 'when level is unit' do
      it 'returns a pattern' do
        expect(subject.pattern(:unit))
          .to eq("spec/{bin,config,db,dependencies,factories,finders,frontend,graphql,haml_lint,helpers,initializers,javascripts,lib,migrations,models,policies,presenters,rack_servers,routing,rubocop,serializers,services,sidekiq,tasks,uploaders,validators,views,workers,elastic_integration}{,/**/}*_spec.rb")
      end
    end

    context 'when level is migration' do
      it 'returns a pattern' do
        expect(subject.pattern(:migration))
          .to eq("spec/{migrations,lib/gitlab/background_migration}{,/**/}*_spec.rb")
      end
    end

    context 'when level is integration' do
      it 'returns a pattern' do
        expect(subject.pattern(:integration))
          .to eq("spec/{controllers,mailers,requests}{,/**/}*_spec.rb")
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
          .to eq("ee/spec/{features}{,/**/}*_spec.rb")
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

    context 'when level is geo' do
      it 'returns a regexp' do
        expect(subject.regexp(:geo))
        .to eq(%r{spec/})
      end
    end

    context 'when level is unit' do
      it 'returns a regexp' do
        expect(subject.regexp(:unit))
          .to eq(%r{spec/(bin|config|db|dependencies|factories|finders|frontend|graphql|haml_lint|helpers|initializers|javascripts|lib|migrations|models|policies|presenters|rack_servers|routing|rubocop|serializers|services|sidekiq|tasks|uploaders|validators|views|workers|elastic_integration)})
      end
    end

    context 'when level is migration' do
      it 'returns a regexp' do
        expect(subject.regexp(:migration))
          .to eq(%r{spec/(migrations|lib/gitlab/background_migration)})
      end
    end

    context 'when level is integration' do
      it 'returns a regexp' do
        expect(subject.regexp(:integration))
          .to eq(%r{spec/(controllers|mailers|requests)})
      end
    end

    context 'when level is system' do
      it 'returns a regexp' do
        expect(subject.regexp(:system))
          .to eq(%r{spec/(features)})
      end
    end

    context 'with a prefix' do
      it 'returns a regexp' do
        expect(described_class.new('ee/').regexp(:system))
          .to eq(%r{ee/spec/(features)})
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

    it 'returns the correct level for a migration test' do
      expect(subject.level_for('spec/migrations/add_default_and_free_plans_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for a background_migration test' do
      expect(subject.level_for('spec/lib/gitlab/background_migration/archive_legacy_traces_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for a geo migration test' do
      expect(described_class.new('ee/').level_for('ee/spec/migrations/geo/migrate_ci_job_artifacts_to_separate_registry_spec.rb')).to eq(:migration)
    end

    it 'returns the correct level for an integration test' do
      expect(subject.level_for('spec/mailers/abuse_report_mailer_spec.rb')).to eq(:integration)
    end

    it 'returns the correct level for a system test' do
      expect(subject.level_for('spec/features/abuse_report_spec.rb')).to eq(:system)
    end

    it 'raises an error for an unknown level' do
      expect { subject.level_for('spec/unknown/foo_spec.rb') }
        .to raise_error(described_class::UnknownTestLevelError,
          %r{Test level for spec/unknown/foo_spec.rb couldn't be set. Please rename the file properly or change the test level detection regexes in .+/lib/quality/test_level.rb.})
    end
  end
end

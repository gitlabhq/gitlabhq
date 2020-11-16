# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/test_file_finder'

RSpec.describe Tooling::TestFileFinder do
  subject { described_class.new(file) }

  describe '#test_files' do
    context 'when given non .rb files' do
      let(:file) { 'app/assets/images/emoji.png' }

      it 'does not return a test file' do
        expect(subject.test_files).to be_empty
      end
    end

    context 'when given file in app/' do
      let(:file) { 'app/finders/admin/projects_finder.rb' }

      it 'returns the matching app spec file' do
        expect(subject.test_files).to contain_exactly('spec/finders/admin/projects_finder_spec.rb')
      end
    end

    context 'when given file in lib/' do
      let(:file) { 'lib/banzai/color_parser.rb' }

      it 'returns the matching app spec file' do
        expect(subject.test_files).to contain_exactly('spec/lib/banzai/color_parser_spec.rb')
      end
    end

    context 'when given a file in tooling/' do
      let(:file) { 'tooling/lib/tooling/test_file_finder.rb' }

      it 'returns the matching tooling test' do
        expect(subject.test_files).to contain_exactly('spec/tooling/lib/tooling/test_file_finder_spec.rb')
      end
    end

    context 'when given a test file' do
      let(:file) { 'spec/lib/banzai/color_parser_spec.rb' }

      it 'returns the matching test file itself' do
        expect(subject.test_files).to contain_exactly('spec/lib/banzai/color_parser_spec.rb')
      end
    end

    context 'when given an app file in ee/' do
      let(:file) { 'ee/app/models/analytics/cycle_analytics/group_level.rb' }

      it 'returns the matching ee/ test file' do
        expect(subject.test_files).to contain_exactly('ee/spec/models/analytics/cycle_analytics/group_level_spec.rb')
      end
    end

    context 'when given an ee extension module file' do
      let(:file) { 'ee/app/models/ee/user.rb' }

      it 'returns the matching ee/ class test file, ee extension module test file and the foss class test file' do
        test_files = ['ee/spec/models/user_spec.rb', 'ee/spec/models/ee/user_spec.rb', 'spec/app/models/user_spec.rb']
        expect(subject.test_files).to contain_exactly(*test_files)
      end
    end

    context 'when given a test file in ee/' do
      let(:file) { 'ee/spec/models/container_registry/event_spec.rb' }

      it 'returns the test file itself' do
        expect(subject.test_files).to contain_exactly('ee/spec/models/container_registry/event_spec.rb')
      end
    end

    context 'when given a module test file in ee/' do
      let(:file) { 'ee/spec/models/ee/appearance_spec.rb' }

      it 'returns the matching module test file itself and the corresponding spec model test file' do
        test_files = ['ee/spec/models/ee/appearance_spec.rb', 'spec/models/appearance_spec.rb']
        expect(subject.test_files).to contain_exactly(*test_files)
      end
    end

    context 'when given a factory file' do
      let(:file) { 'spec/factories/users.rb' }

      it 'returns spec/factories_spec.rb file' do
        expect(subject.test_files).to contain_exactly('spec/factories_spec.rb')
      end
    end

    context 'when given an ee factory file' do
      let(:file) { 'ee/spec/factories/users.rb' }

      it 'returns spec/factories_spec.rb file' do
        expect(subject.test_files).to contain_exactly('spec/factories_spec.rb')
      end
    end

    context 'when given db/structure.sql' do
      let(:file) { 'db/structure.sql' }

      it 'returns spec/db/schema_spec.rb' do
        expect(subject.test_files).to contain_exactly('spec/db/schema_spec.rb')
      end
    end

    context 'when given an initializer' do
      let(:file) { 'config/initializers/action_mailer_hooks.rb' }

      it 'returns the matching initializer spec' do
        expect(subject.test_files).to contain_exactly('spec/initializers/action_mailer_hooks_spec.rb')
      end
    end

    context 'when given a haml view' do
      let(:file) { 'app/views/admin/users/_user.html.haml' }

      it 'returns the matching view spec' do
        expect(subject.test_files).to contain_exactly('spec/views/admin/users/_user.html.haml_spec.rb')
      end
    end

    context 'when given a haml view in ee/' do
      let(:file) { 'ee/app/views/admin/users/_user.html.haml' }

      it 'returns the matching view spec' do
        expect(subject.test_files).to contain_exactly('ee/spec/views/admin/users/_user.html.haml_spec.rb')
      end
    end

    context 'when given a migration file' do
      let(:file) { 'db/migrate/20191023152913_add_default_and_free_plans.rb' }

      it 'returns the matching migration spec' do
        test_files = %w[
          spec/migrations/add_default_and_free_plans_spec.rb
          spec/migrations/20191023152913_add_default_and_free_plans_spec.rb
        ]
        expect(subject.test_files).to contain_exactly(*test_files)
      end
    end

    context 'when given a post-migration file' do
      let(:file) { 'db/post_migrate/20200608072931_backfill_imported_snippet_repositories.rb' }

      it 'returns the matching migration spec' do
        test_files = %w[
          spec/migrations/backfill_imported_snippet_repositories_spec.rb
          spec/migrations/20200608072931_backfill_imported_snippet_repositories_spec.rb
        ]
        expect(subject.test_files).to contain_exactly(*test_files)
      end
    end

    context 'with foss_test_only: true' do
      subject { Tooling::TestFileFinder.new(file, foss_test_only: true) }

      context 'when given a module file in ee/' do
        let(:file) { 'ee/app/models/ee/user.rb' }

        it 'returns only the corresponding spec model test file in foss' do
          expect(subject.test_files).to contain_exactly('spec/app/models/user_spec.rb')
        end
      end

      context 'when given an app file in ee/' do
        let(:file) { 'ee/app/models/approval.rb' }

        it 'returns no test file in foss' do
          expect(subject.test_files).to be_empty
        end
      end
    end
  end
end

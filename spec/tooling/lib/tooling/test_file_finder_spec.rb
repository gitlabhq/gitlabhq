# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/test_file_finder'

RSpec.describe Tooling::TestFileFinder do
  subject { Tooling::TestFileFinder.new(file) }

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
      let(:file) { 'tooling/lib/quality/test_file_finder.rb' }

      it 'returns the matching tooling test' do
        expect(subject.test_files).to contain_exactly('spec/tooling/lib/quality/test_file_finder_spec.rb')
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

    context 'when given a module file in ee/' do
      let(:file) { 'ee/app/models/ee/user.rb' }

      it 'returns the matching ee/ module test file and the ee/ model test file' do
        test_files = ['ee/spec/models/ee/user_spec.rb', 'spec/app/models/user_spec.rb']
        expect(subject.test_files).to contain_exactly(*test_files)
      end
    end

    context 'when given a lib file in ee/' do
      let(:file) { 'ee/lib/flipper_session.rb' }

      it 'returns the matching ee/ lib test file' do
        expect(subject.test_files).to contain_exactly('ee/spec/lib/flipper_session_spec.rb')
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

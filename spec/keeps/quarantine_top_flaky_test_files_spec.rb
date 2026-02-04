# frozen_string_literal: true

require 'spec_helper'
require './keeps/quarantine_top_flaky_test_files'

RSpec.describe Keeps::QuarantineTopFlakyTestFiles, feature_category: :tooling do
  let(:keep) { described_class.new }
  let(:gitlab_api_helper) { instance_double(Keeps::Helpers::GitlabApiHelper) }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_file_path) { File.join(tmp_dir, 'spec/models/user_spec.rb') }

  before do
    allow(keep).to receive(:gitlab_api_helper).and_return(gitlab_api_helper)
    FileUtils.mkdir_p(File.dirname(spec_file_path))
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  describe '#each_identified_change' do
    let(:flaky_test_file_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1',
        'description' => <<~DESC
          | Spec file | spec/models/user_spec.rb |
        DESC
      }
    end

    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    before do
      File.write(spec_file_path, spec_content)
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path).with("../spec/models/user_spec.rb", anything).and_return(spec_file_path)

      allow(gitlab_api_helper).to receive(:query_api) do |_url, &block|
        block.call(flaky_test_file_issue)
      end
    end

    it 'yields a change for valid flaky test file issues' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.size).to eq(1)
      expect(changes.first).to be_a(Gitlab::Housekeeper::Change)
      expect(changes.first.context[:flaky_test_file_issue]).to eq(flaky_test_file_issue)
      expect(changes.first.identifiers).to eq(['QuarantineTopFlakyTestFiles', 'spec/models/user_spec.rb'])
    end
  end

  describe '#make_change!' do
    let(:flaky_test_file_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1',
        'description' => <<~DESC
          | Spec file | spec/models/user_spec.rb |
          spec/models/user_spec.rb:4
          **Product Group:** development_analytics\n
        DESC
      }
    end

    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:change) do
      Gitlab::Housekeeper::Change.new.tap do |c|
        c.context = { flaky_test_file_issue: flaky_test_file_issue }
        c.identifiers = ['QuarantineTopFlakyTestFiles', 'spec/models/user_spec.rb']
      end
    end

    before do
      File.write(spec_file_path, spec_content)
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path).with("../spec/models/user_spec.rb", anything).and_return(spec_file_path)

      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
    end

    it 'quarantines the flaky test file and constructs the change' do
      keep.make_change!(change)

      updated_content = File.read(spec_file_path)
      expect(updated_content).to include(
        "quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1', type: 'flaky' }"
      )

      expect(change.title).to eq('Quarantine flaky user_spec.rb')
      expect(change.changed_files).to eq(['spec/models/user_spec.rb'])
      expect(change.labels).to include('quarantine', 'quarantine::flaky', 'group::development analytics')
      expect(change.description).to include('spec/models/user_spec.rb')
      expect(change.description).to include(flaky_test_file_issue['web_url'])
    end
  end

  describe '#update_file_content_per_test' do
    context 'when test uses it_behaves_like' do
      let(:spec_content) do
        <<~RUBY
          # frozen_string_literal: true

          RSpec.describe User do
            context 'when user is valid' do
              it_behaves_like 'a valid user'
            end
          end
        RUBY
      end

      let(:flaky_test_file_issue) do
        { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
      end

      before do
        File.write(spec_file_path, spec_content)
      end

      it 'adds quarantine metadata to shared example' do
        failing_tests = ['spec/models/user_spec.rb:5']
        result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

        expect(result).to include(
          "quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1', type: 'flaky' }"
        )
      end
    end

    context 'when test uses it { }' do
      let(:spec_content) do
        <<~RUBY
          # frozen_string_literal: true

          RSpec.describe User do
            it { expect(User.create).to be_valid }
          end
        RUBY
      end

      let(:flaky_test_file_issue) do
        { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
      end

      before do
        File.write(spec_file_path, spec_content)
      end

      it 'adds quarantine metadata to it example without name' do
        failing_tests = ['spec/models/user_spec.rb:4']
        result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

        expect(result).to include(
          "quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1', type: 'flaky' }"
        )
      end
    end

    context 'when file content did not change' do
      let(:spec_content) do
        <<~RUBY
          # frozen_string_literal: true

          RSpec.describe User do
            p 'dummy line'
          end
        RUBY
      end

      let(:flaky_test_file_issue) do
        { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
      end

      before do
        File.write(spec_file_path, spec_content)
      end

      it 'returns nil' do
        failing_tests = ['spec/models/user_spec.rb:4']
        result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

        expect(result).to be_nil
      end
    end
  end

  describe '#find_quarantine_line_for_it_example' do
    it 'finds the line ending with "do\\n" starting from test_line' do
      file_lines = [
        "RSpec.describe User do\n",
        "  it 'creates a new user' do\n",
        "    expect(User.create).to be_valid\n",
        "  end\n",
        "end\n"
      ]

      result = keep.send(:find_quarantine_line_for_it_example, file_lines, 1)

      expect(result).to eq(1)
    end

    it 'returns nil if quarantine already exists' do
      file_lines = [
        "RSpec.describe User do\n",
        "  it 'creates a new user', quarantine: { issue: 'url', type: 'flaky' } do\n",
        "    expect(User.create).to be_valid\n",
        "  end\n",
        "end\n"
      ]

      result = keep.send(:find_quarantine_line_for_it_example, file_lines, 1)

      expect(result).to be_nil
    end

    it 'returns nil if no line ending with "do\\n" is found within check_lines' do
      file_lines = [
        "RSpec.describe User do\n",
        "  it 'creates a new user'\n",
        "    expect(User.create).to be_valid\n",
        "  end\n",
        "end\n"
      ]

      result = keep.send(:find_quarantine_line_for_it_example, file_lines, 1, check_lines: 2)

      expect(result).to be_nil
    end
  end

  describe '#update_file_content_per_test with qa/ prefix' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
    end

    before do
      File.write(spec_file_path, spec_content)
    end

    it 'handles tests without qa/ prefix' do
      failing_tests = ['spec/models/user_spec.rb:4']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      expect(result).to include(
        "quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1', type: 'flaky' }"
      )
    end

    it 'handles qa/ prefix in failing tests' do
      failing_tests = ['qa/spec/models/user_spec.rb:4']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      expect(result).to include(
        "quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1', type: 'flaky' }"
      )
    end
  end

  describe '#update_file_content_per_test with invalid line numbers' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
    end

    before do
      File.write(spec_file_path, spec_content)
    end

    it 'skips tests with invalid line numbers' do
      failing_tests = ['spec/models/user_spec.rb:999']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      # File should not be modified since line 999 doesn't exist
      expect(result).to be_nil
    end

    it 'skips tests with negative line numbers' do
      failing_tests = ['spec/models/user_spec.rb:0']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      # File should not be modified since line 0 is invalid
      expect(result).to be_nil
    end
  end

  describe '#update_file_content_per_test with unrecognized line types' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          describe 'some behavior' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
    end

    before do
      File.write(spec_file_path, spec_content)
    end

    it 'skips tests on unrecognized line types' do
      failing_tests = ['spec/models/user_spec.rb:5']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      # File should not be modified since line 5 is not an it block
      expect(result).to be_nil
    end
  end

  describe '#update_file_content_per_test when quarantine line is not found' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      { 'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1' }
    end

    before do
      File.write(spec_file_path, spec_content)
    end

    it 'skips tests when find_quarantine_line returns nil' do
      # Mock find_quarantine_line_for_it_example to return nil
      allow(keep).to receive(:find_quarantine_line_for_it_example).and_return(nil)

      failing_tests = ['spec/models/user_spec.rb:4']
      result = keep.send(:update_file_content_per_test, spec_file_path, flaky_test_file_issue, failing_tests)

      # File should not be modified since quarantine line was not found
      expect(result).to be_nil
    end
  end

  describe '#prepare_change with qa/ prefix handling' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1',
        'description' => <<~DESC
          | Spec file | qa/spec/models/user_spec.rb |
          qa/spec/models/user_spec.rb:4
          **Product Group:** development_analytics\n
        DESC
      }
    end

    let(:change) do
      Gitlab::Housekeeper::Change.new.tap do |c|
        c.context = { flaky_test_file_issue: flaky_test_file_issue }
        c.identifiers = ['QuarantineTopFlakyTestFiles', 'qa/spec/models/user_spec.rb']
      end
    end

    before do
      File.write(spec_file_path, spec_content)
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path)
        .with("../qa/qa/spec/models/user_spec.rb", anything)
        .and_return(spec_file_path)

      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
    end

    it 'handles qa/ prefix in failing tests from issue description' do
      keep.send(:prepare_change, change, flaky_test_file_issue)

      # Verify that the change was constructed with the qa/ prefix
      expect(change.title).to eq('Quarantine flaky user_spec.rb')
      expect(change.changed_files).to eq(['qa/qa/spec/models/user_spec.rb'])
    end
  end

  describe '#prepare_change when failing_tests is empty' do
    let(:spec_content) do
      <<~RUBY
        # frozen_string_literal: true

        RSpec.describe User do
          it 'creates a new user' do
            expect(User.create).to be_valid
          end
        end
      RUBY
    end

    let(:flaky_test_file_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/1',
        'description' => <<~DESC
          | Spec file | spec/models/user_spec.rb |
        DESC
      }
    end

    let(:change) do
      Gitlab::Housekeeper::Change.new.tap do |c|
        c.context = { flaky_test_file_issue: flaky_test_file_issue }
        c.identifiers = ['QuarantineTopFlakyTestFiles', 'spec/models/user_spec.rb']
      end
    end

    before do
      File.write(spec_file_path, spec_content)
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path).with("../spec/models/user_spec.rb", anything).and_return(spec_file_path)
      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
    end

    it 'returns early without modifying the file when no failing tests are found' do
      original_content = File.read(spec_file_path)

      keep.send(:prepare_change, change, flaky_test_file_issue)

      # Verify that the file was not modified
      expect(File.read(spec_file_path)).to eq(original_content)
      # Verify that rubocop_autocorrect was not called
      expect(::Gitlab::Housekeeper::Shell).not_to have_received(:rubocop_autocorrect)
      # Verify that change was not constructed
      expect(change.title).to be_nil
      expect(change.changed_files).to be_nil
    end
  end
end

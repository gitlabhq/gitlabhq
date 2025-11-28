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
        'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321',
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
        'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321',
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
        "quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321', type: 'flaky' }"
      )

      expect(change.title).to eq('Quarantine flaky user_spec.rb')
      expect(change.changed_files).to eq(['spec/models/user_spec.rb'])
      expect(change.labels).to include('quarantine', 'quarantine::flaky')
      expect(change.description).to include('spec/models/user_spec.rb')
      expect(change.description).to include(flaky_test_file_issue['web_url'])
    end
  end

  describe '#update_file_content' do
    context 'when RSpec.describe uses standard syntax' do
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
        { 'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321' }
      end

      before do
        File.write(spec_file_path, spec_content)
      end

      it 'adds quarantine metadata to RSpec.describe block' do
        result = keep.send(:update_file_content, spec_file_path, 'spec/models/user_spec.rb', flaky_test_file_issue)

        expect(result).to include("RSpec.describe User,")
        expect(result).to include(
          "quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321', type: 'flaky' }"
        )
      end
    end

    context 'when RSpec.describe uses parenthesis syntax' do
      let(:spec_content) do
        <<~RUBY
          # frozen_string_literal: true

          RSpec.describe(User) do
            it 'creates a new user' do
              expect(User.create).to be_valid
            end
          end
        RUBY
      end

      let(:flaky_test_file_issue) do
        { 'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321' }
      end

      before do
        File.write(spec_file_path, spec_content)
      end

      it 'adds quarantine metadata to RSpec.describe block' do
        result = keep.send(:update_file_content, spec_file_path, 'spec/models/user_spec.rb', flaky_test_file_issue)

        expect(result).to include("RSpec.describe(User,")
        expect(result).to include(
          "quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/54321', type: 'flaky' }"
        )
      end
    end
  end
end

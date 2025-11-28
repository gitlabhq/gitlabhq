# frozen_string_literal: true

require 'spec_helper'
require './keeps/quarantine_flaky_tests'

RSpec.describe Keeps::QuarantineFlakyTests, feature_category: :tooling do
  let(:keep) { described_class.new }
  let(:gitlab_api_helper) { instance_double(Keeps::Helpers::GitlabApiHelper) }
  let(:groups_helper) { instance_double(Keeps::Helpers::Groups) }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:spec_file_path) { File.join(tmp_dir, 'spec/models/user_spec.rb') }

  before do
    allow(keep).to receive_messages(
      gitlab_api_helper: gitlab_api_helper,
      groups_helper: groups_helper
    )
    FileUtils.mkdir_p(File.dirname(spec_file_path))
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  describe '#each_identified_change' do
    let(:flaky_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345',
        'description' => <<~DESC,
          | File URL | [`spec/models/user_spec.rb#L4`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/models/user_spec.rb#L4) |
          | Description | creates a new user |
        DESC
        'labels' => ['test', 'failure::flaky-test', 'flakiness::1', 'group::authentication']
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
      allow(keep).to receive(:puts)

      allow(gitlab_api_helper).to receive(:query_api) do |_url, &block|
        block.call(flaky_issue)
      end
    end

    it 'yields a change for valid flaky issues' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.size).to eq(3) # One for each flakiness label
      expect(changes.first).to be_a(Gitlab::Housekeeper::Change)
      expect(changes.first.context[:flaky_issue]).to eq(flaky_issue)
      expect(changes.first.identifiers).to eq(['QuarantineFlakyTests', 'spec/models/user_spec.rb', '4'])
    end
  end

  describe '#make_change!' do
    let(:flaky_issue) do
      {
        'web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345',
        'description' => <<~DESC,
          | File URL | [`spec/models/user_spec.rb#L4`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/models/user_spec.rb#L4) |
          | Description | creates a new user |
        DESC
        'labels' => ['test', 'failure::flaky-test', 'flakiness::1', 'group::authentication']
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
        c.context = { flaky_issue: flaky_issue }
        c.identifiers = ['QuarantineFlakyTests', 'spec/models/user_spec.rb', '4']
      end
    end

    let(:group_data) { { backend_engineers: ['@john_doe'] } }

    before do
      File.write(spec_file_path, spec_content)
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path).with("../spec/models/user_spec.rb", anything).and_return(spec_file_path)

      allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
      allow(groups_helper).to receive(:group_for_group_label).with('group::authentication').and_return(group_data)
      allow(groups_helper).to receive(:pick_reviewer).with(group_data, anything).and_return(['@john_doe'])
      allow(keep).to receive(:puts)
    end

    it 'quarantines the flaky test and constructs the change' do
      keep.make_change!(change)

      updated_content = File.read(spec_file_path)
      expect(updated_content).to include("quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/12345'")

      expect(change.title).to eq('Quarantine a flaky test')
      expect(change.changed_files).to eq(['spec/models/user_spec.rb'])
      expect(change.labels).to include('quarantine', 'quarantine::flaky', 'group::authentication')
      expect(change.reviewers).to eq(['@john_doe'])
      expect(change.description).to include('creates a new user')
    end
  end
end

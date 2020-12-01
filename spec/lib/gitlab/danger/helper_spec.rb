# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require_relative 'danger_spec_helper'

require 'gitlab/danger/helper'

RSpec.describe Gitlab::Danger::Helper do
  using RSpec::Parameterized::TableSyntax
  include DangerSpecHelper

  let(:fake_git) { double('fake-git') }

  let(:mr_author) { nil }
  let(:fake_gitlab) { double('fake-gitlab', mr_author: mr_author) }

  let(:fake_danger) { new_fake_danger.include(described_class) }

  subject(:helper) { fake_danger.new(git: fake_git, gitlab: fake_gitlab) }

  describe '#gitlab_helper' do
    context 'when gitlab helper is not available' do
      let(:fake_gitlab) { nil }

      it 'returns nil' do
        expect(helper.gitlab_helper).to be_nil
      end
    end

    context 'when gitlab helper is available' do
      it 'returns the gitlab helper' do
        expect(helper.gitlab_helper).to eq(fake_gitlab)
      end
    end

    context 'when danger gitlab plugin is not available' do
      it 'returns nil' do
        invalid_danger = Class.new do
          include Gitlab::Danger::Helper
        end.new

        expect(invalid_danger.gitlab_helper).to be_nil
      end
    end
  end

  describe '#release_automation?' do
    context 'when gitlab helper is not available' do
      it 'returns false' do
        expect(helper.release_automation?).to be_falsey
      end
    end

    context 'when gitlab helper is available' do
      context "but the MR author isn't the RELEASE_TOOLS_BOT" do
        let(:mr_author) { 'johnmarston' }

        it 'returns false' do
          expect(helper.release_automation?).to be_falsey
        end
      end

      context 'and the MR author is the RELEASE_TOOLS_BOT' do
        let(:mr_author) { described_class::RELEASE_TOOLS_BOT }

        it 'returns true' do
          expect(helper.release_automation?).to be_truthy
        end
      end
    end
  end

  describe '#all_changed_files' do
    subject { helper.all_changed_files }

    it 'interprets a list of changes from the danger git plugin' do
      expect(fake_git).to receive(:added_files) { %w[a b c.old] }
      expect(fake_git).to receive(:modified_files) { %w[d e] }
      expect(fake_git)
        .to receive(:renamed_files)
        .at_least(:once)
        .and_return([{ before: 'c.old', after: 'c.new' }])

      is_expected.to contain_exactly('a', 'b', 'c.new', 'd', 'e')
    end
  end

  describe '#changed_lines' do
    subject { helper.changed_lines('changed_file.rb') }

    before do
      allow(fake_git).to receive(:diff_for_file).with('changed_file.rb').and_return(diff)
    end

    context 'when file has diff' do
      let(:diff) { double(:diff, patch: "+ # New change here\n+ # New change there") }

      it 'returns file changes' do
        is_expected.to eq(['+ # New change here', '+ # New change there'])
      end
    end

    context 'when file has no diff (renamed without changes)' do
      let(:diff) { nil }

      it 'returns a blank array' do
        is_expected.to eq([])
      end
    end
  end

  describe "changed_files" do
    it 'returns list of changed files matching given regex' do
      expect(helper).to receive(:all_changed_files).and_return(%w[migration.rb usage_data.rb])

      expect(helper.changed_files(/usage_data/)).to contain_exactly('usage_data.rb')
    end
  end

  describe '#all_ee_changes' do
    subject { helper.all_ee_changes }

    it 'returns all changed files starting with ee/' do
      expect(helper).to receive(:all_changed_files).and_return(%w[fr/ee/beer.rb ee/wine.rb ee/lib/ido.rb ee.k])

      is_expected.to match_array(%w[ee/wine.rb ee/lib/ido.rb])
    end
  end

  describe '#ee?' do
    subject { helper.ee? }

    it 'returns true if CI_PROJECT_NAME if set to gitlab' do
      stub_env('CI_PROJECT_NAME', 'gitlab')
      expect(Dir).not_to receive(:exist?)

      is_expected.to be_truthy
    end

    it 'delegates to CHANGELOG-EE.md existence if CI_PROJECT_NAME is set to something else' do
      stub_env('CI_PROJECT_NAME', 'something else')
      expect(Dir).to receive(:exist?).with(File.expand_path('../../../../ee', __dir__)) { true }

      is_expected.to be_truthy
    end

    it 'returns true if ee exists' do
      stub_env('CI_PROJECT_NAME', nil)
      expect(Dir).to receive(:exist?).with(File.expand_path('../../../../ee', __dir__)) { true }

      is_expected.to be_truthy
    end

    it "returns false if ee doesn't exist" do
      stub_env('CI_PROJECT_NAME', nil)
      expect(Dir).to receive(:exist?).with(File.expand_path('../../../../ee', __dir__)) { false }

      is_expected.to be_falsy
    end
  end

  describe '#project_name' do
    subject { helper.project_name }

    it 'returns gitlab if ee? returns true' do
      expect(helper).to receive(:ee?) { true }

      is_expected.to eq('gitlab')
    end

    it 'returns gitlab-ce if ee? returns false' do
      expect(helper).to receive(:ee?) { false }

      is_expected.to eq('gitlab-foss')
    end
  end

  describe '#markdown_list' do
    it 'creates a markdown list of items' do
      items = %w[a b]

      expect(helper.markdown_list(items)).to eq("* `a`\n* `b`")
    end

    it 'wraps items in <details> when there are more than 10 items' do
      items = ('a'..'k').to_a

      expect(helper.markdown_list(items)).to match(%r{<details>[^<]+</details>})
    end
  end

  describe '#changes_by_category' do
    it 'categorizes changed files' do
      expect(fake_git).to receive(:added_files) { %w[foo foo.md foo.rb foo.js db/migrate/foo lib/gitlab/database/foo.rb qa/foo ee/changelogs/foo.yml] }
      allow(fake_git).to receive(:modified_files) { [] }
      allow(fake_git).to receive(:renamed_files) { [] }

      expect(helper.changes_by_category).to eq(
        backend: %w[foo.rb],
        database: %w[db/migrate/foo lib/gitlab/database/foo.rb],
        frontend: %w[foo.js],
        none: %w[ee/changelogs/foo.yml foo.md],
        qa: %w[qa/foo],
        unknown: %w[foo]
      )
    end
  end

  describe '#categories_for_file' do
    before do
      allow(fake_git).to receive(:diff_for_file).with('usage_data.rb') { double(:diff, patch: "+ count(User.active)") }
    end

    where(:path, :expected_categories) do
      'usage_data.rb'   | [:database, :backend]
      'doc/foo.md'      | [:docs]
      'CONTRIBUTING.md' | [:docs]
      'LICENSE'         | [:docs]
      'MAINTENANCE.md'  | [:docs]
      'PHILOSOPHY.md'   | [:docs]
      'PROCESS.md'      | [:docs]
      'README.md'       | [:docs]

      'ee/doc/foo'      | [:unknown]
      'ee/README'       | [:unknown]

      'app/assets/foo'       | [:frontend]
      'app/views/foo'        | [:frontend]
      'public/foo'           | [:frontend]
      'scripts/frontend/foo' | [:frontend]
      'spec/javascripts/foo' | [:frontend]
      'spec/frontend/bar'    | [:frontend]
      'vendor/assets/foo'    | [:frontend]
      'babel.config.js'      | [:frontend]
      'jest.config.js'       | [:frontend]
      'package.json'         | [:frontend]
      'yarn.lock'            | [:frontend]
      'config/foo.js'        | [:frontend]
      'config/deep/foo.js'   | [:frontend]

      'ee/app/assets/foo'       | [:frontend]
      'ee/app/views/foo'        | [:frontend]
      'ee/spec/javascripts/foo' | [:frontend]
      'ee/spec/frontend/bar'    | [:frontend]

      '.gitlab/ci/frontend.gitlab-ci.yml' | %i[frontend engineering_productivity]

      'app/models/foo'             | [:backend]
      'bin/foo'                    | [:backend]
      'config/foo'                 | [:backend]
      'lib/foo'                    | [:backend]
      'rubocop/foo'                | [:backend]
      '.rubocop.yml'               | [:backend]
      '.rubocop_todo.yml'          | [:backend]
      '.rubocop_manual_todo.yml'   | [:backend]
      'spec/foo'                   | [:backend]
      'spec/foo/bar'               | [:backend]

      'ee/app/foo'      | [:backend]
      'ee/bin/foo'      | [:backend]
      'ee/spec/foo'     | [:backend]
      'ee/spec/foo/bar' | [:backend]

      'spec/features/foo'                            | [:test]
      'ee/spec/features/foo'                         | [:test]
      'spec/support/shared_examples/features/foo'    | [:test]
      'ee/spec/support/shared_examples/features/foo' | [:test]
      'spec/support/shared_contexts/features/foo'    | [:test]
      'ee/spec/support/shared_contexts/features/foo' | [:test]
      'spec/support/helpers/features/foo'            | [:test]
      'ee/spec/support/helpers/features/foo'         | [:test]

      'generator_templates/foo' | [:backend]
      'vendor/languages.yml'    | [:backend]
      'file_hooks/examples/'    | [:backend]

      'Gemfile'        | [:backend]
      'Gemfile.lock'   | [:backend]
      'Rakefile'       | [:backend]
      'FOO_VERSION'    | [:backend]

      'Dangerfile'                                            | [:engineering_productivity]
      'danger/commit_messages/Dangerfile'                     | [:engineering_productivity]
      'ee/danger/commit_messages/Dangerfile'                  | [:engineering_productivity]
      'danger/commit_messages/'                               | [:engineering_productivity]
      'ee/danger/commit_messages/'                            | [:engineering_productivity]
      '.gitlab-ci.yml'                                        | [:engineering_productivity]
      '.gitlab/ci/cng.gitlab-ci.yml'                          | [:engineering_productivity]
      '.gitlab/ci/ee-specific-checks.gitlab-ci.yml'           | [:engineering_productivity]
      'scripts/foo'                                           | [:engineering_productivity]
      'lib/gitlab/danger/foo'                                 | [:engineering_productivity]
      'ee/lib/gitlab/danger/foo'                              | [:engineering_productivity]
      'lefthook.yml'                                          | [:engineering_productivity]
      '.editorconfig'                                         | [:engineering_productivity]
      'tooling/bin/find_foss_tests'                           | [:engineering_productivity]
      '.codeclimate.yml'                                      | [:engineering_productivity]
      '.gitlab/CODEOWNERS'                                    | [:engineering_productivity]

      'lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'   | [:ci_template]
      'lib/gitlab/ci/templates/dotNET-Core.yml'               | [:ci_template]

      'ee/FOO_VERSION' | [:unknown]

      'db/schema.rb'                                              | [:database]
      'db/structure.sql'                                          | [:database]
      'db/migrate/foo'                                            | [:database]
      'db/post_migrate/foo'                                       | [:database]
      'ee/db/migrate/foo'                                         | [:database]
      'ee/db/post_migrate/foo'                                    | [:database]
      'ee/db/geo/migrate/foo'                                     | [:database]
      'ee/db/geo/post_migrate/foo'                                | [:database]
      'app/models/project_authorization.rb'                       | [:database]
      'app/services/users/refresh_authorized_projects_service.rb' | [:database]
      'lib/gitlab/background_migration.rb'                        | [:database]
      'lib/gitlab/background_migration/foo'                       | [:database]
      'ee/lib/gitlab/background_migration/foo'                    | [:database]
      'lib/gitlab/database.rb'                                    | [:database]
      'lib/gitlab/database/foo'                                   | [:database]
      'ee/lib/gitlab/database/foo'                                | [:database]
      'lib/gitlab/github_import.rb'                               | [:database]
      'lib/gitlab/github_import/foo'                              | [:database]
      'lib/gitlab/sql/foo'                                        | [:database]
      'rubocop/cop/migration/foo'                                 | [:database]

      'db/fixtures/foo.rb'                                 | [:backend]
      'ee/db/fixtures/foo.rb'                              | [:backend]
      'doc/api/graphql/reference/gitlab_schema.graphql'    | [:backend]
      'doc/api/graphql/reference/gitlab_schema.json'       | [:backend]

      'qa/foo' | [:qa]
      'ee/qa/foo' | [:qa]

      'changelogs/foo'    | [:none]
      'ee/changelogs/foo' | [:none]
      'locale/gitlab.pot' | [:none]

      'FOO'          | [:unknown]
      'foo'          | [:unknown]

      'foo/bar.rb'  | [:backend]
      'foo/bar.js'  | [:frontend]
      'foo/bar.txt' | [:none]
      'foo/bar.md'  | [:none]
    end

    with_them do
      subject { helper.categories_for_file(path) }

      it { is_expected.to eq(expected_categories) }
    end

    context 'having specific changes' do
      it 'has database and backend categories' do
        changed_files = ['usage_data.rb', 'lib/gitlab/usage_data.rb', 'ee/lib/ee/gitlab/usage_data.rb']

        changed_files.each do |file|
          allow(fake_git).to receive(:diff_for_file).with(file) { double(:diff, patch: "+ count(User.active)") }

          expect(helper.categories_for_file(file)).to eq([:database, :backend])
        end
      end

      it 'has backend category' do
        allow(fake_git).to receive(:diff_for_file).with('usage_data.rb') { double(:diff, patch: "+ alt_usage_data(User.active)") }

        expect(helper.categories_for_file('usage_data.rb')).to eq([:backend])
      end

      it 'has backend category for changes outside usage_data files' do
        allow(fake_git).to receive(:diff_for_file).with('user.rb') { double(:diff, patch: "+ count(User.active)") }

        expect(helper.categories_for_file('user.rb')).to eq([:backend])
      end

      it 'has backend category for files that are not usage_data.rb' do
        changed_file = 'usage_data/topology.rb'
        allow(fake_git).to receive(:diff_for_file).with(changed_file) { double(:diff, patch: "+ count(User.active)") }

        expect(helper.categories_for_file(changed_file)).to eq([:backend])
      end
    end
  end

  describe '#label_for_category' do
    where(:category, :expected_label) do
      :backend   | '~backend'
      :database  | '~database'
      :docs      | '~documentation'
      :foo       | '~foo'
      :frontend  | '~frontend'
      :none      | ''
      :qa        | '~QA'
      :engineering_productivity | '~"Engineering Productivity" for CI, Danger'
      :ci_template | '~"ci::templates"'
    end

    with_them do
      subject { helper.label_for_category(category) }

      it { is_expected.to eq(expected_label) }
    end
  end

  describe '#new_teammates' do
    it 'returns an array of Teammate' do
      usernames = %w[filipa iamphil]

      teammates = helper.new_teammates(usernames)

      expect(teammates.map(&:username)).to eq(usernames)
    end
  end

  describe '#sanitize_mr_title' do
    where(:mr_title, :expected_mr_title) do
      'My MR title'      | 'My MR title'
      'WIP: My MR title' | 'My MR title'
      'Draft: My MR title' | 'My MR title'
      '(Draft) My MR title' | 'My MR title'
      '[Draft] My MR title' | 'My MR title'
      '[DRAFT] My MR title' | 'My MR title'
      'DRAFT: My MR title' | 'My MR title'
    end

    with_them do
      subject { helper.sanitize_mr_title(mr_title) }

      it { is_expected.to eq(expected_mr_title) }
    end
  end

  describe '#security_mr?' do
    it 'returns false when `gitlab_helper` is unavailable' do
      expect(helper).to receive(:gitlab_helper).and_return(nil)

      expect(helper).not_to be_security_mr
    end

    it 'returns false when on a normal merge request' do
      expect(fake_gitlab).to receive(:mr_json)
        .and_return('web_url' => 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1')

      expect(helper).not_to be_security_mr
    end

    it 'returns true when on a security merge request' do
      expect(fake_gitlab).to receive(:mr_json)
        .and_return('web_url' => 'https://gitlab.com/gitlab-org/security/gitlab/-/merge_requests/1')

      expect(helper).to be_security_mr
    end
  end

  describe '#draft_mr?' do
    it 'returns false when `gitlab_helper` is unavailable' do
      expect(helper).to receive(:gitlab_helper).and_return(nil)

      expect(helper).not_to be_draft_mr
    end

    it 'returns true for a draft MR' do
      expect(fake_gitlab).to receive(:mr_json)
        .and_return('title' => 'Draft: My MR title')

      expect(helper).to be_draft_mr
    end

    it 'returns false for non draft MR' do
      expect(fake_gitlab).to receive(:mr_json)
        .and_return('title' => 'My MR title')

      expect(helper).not_to be_draft_mr
    end
  end

  describe '#cherry_pick_mr?' do
    it 'returns false when `gitlab_helper` is unavailable' do
      expect(helper).to receive(:gitlab_helper).and_return(nil)

      expect(helper).not_to be_cherry_pick_mr
    end

    context 'when MR title does not mention a cherry-pick' do
      it 'returns false' do
        expect(fake_gitlab).to receive(:mr_json)
          .and_return('title' => 'Add feature xyz')

        expect(helper).not_to be_cherry_pick_mr
      end
    end

    context 'when MR title mentions a cherry-pick' do
      [
        'Cherry Pick !1234',
        'cherry-pick !1234',
        'CherryPick !1234'
      ].each do |mr_title|
        it 'returns true' do
          expect(fake_gitlab).to receive(:mr_json)
            .and_return('title' => mr_title)

          expect(helper).to be_cherry_pick_mr
        end
      end
    end
  end

  describe '#stable_branch?' do
    it 'returns false when `gitlab_helper` is unavailable' do
      expect(helper).to receive(:gitlab_helper).and_return(nil)

      expect(helper).not_to be_stable_branch
    end

    context 'when MR target branch is not a stable branch' do
      it 'returns false' do
        expect(fake_gitlab).to receive(:mr_json)
          .and_return('target_branch' => 'my-feature-branch')

        expect(helper).not_to be_stable_branch
      end
    end

    context 'when MR target branch is a stable branch' do
      %w[
        13-1-stable-ee
        13-1-stable-ee-patch-1
      ].each do |target_branch|
        it 'returns true' do
          expect(fake_gitlab).to receive(:mr_json)
            .and_return('target_branch' => target_branch)

          expect(helper).to be_stable_branch
        end
      end
    end
  end

  describe '#mr_has_label?' do
    it 'returns false when `gitlab_helper` is unavailable' do
      expect(helper).to receive(:gitlab_helper).and_return(nil)

      expect(helper.mr_has_labels?('telemetry')).to be_falsey
    end

    context 'when mr has labels' do
      before do
        mr_labels = ['telemetry', 'telemetry::reviewed']
        expect(fake_gitlab).to receive(:mr_labels).and_return(mr_labels)
      end

      it 'returns true with a matched label' do
        expect(helper.mr_has_labels?('telemetry')).to be_truthy
      end

      it 'returns false with unmatched label' do
        expect(helper.mr_has_labels?('database')).to be_falsey
      end

      it 'returns true with an array of labels' do
        expect(helper.mr_has_labels?(['telemetry', 'telemetry::reviewed'])).to be_truthy
      end

      it 'returns true with multi arguments with matched labels' do
        expect(helper.mr_has_labels?('telemetry', 'telemetry::reviewed')).to be_truthy
      end

      it 'returns false with multi arguments with unmatched labels' do
        expect(helper.mr_has_labels?('telemetry', 'telemetry::non existing')).to be_falsey
      end
    end
  end

  describe '#labels_list' do
    let(:labels) { ['telemetry', 'telemetry::reviewed'] }

    it 'composes the labels string' do
      expect(helper.labels_list(labels)).to eq('~"telemetry", ~"telemetry::reviewed"')
    end

    context 'when passing a separator' do
      it 'composes the labels string with the given separator' do
        expect(helper.labels_list(labels, sep: ' ')).to eq('~"telemetry" ~"telemetry::reviewed"')
      end
    end

    it 'returns empty string for empty array' do
      expect(helper.labels_list([])).to eq('')
    end
  end

  describe '#prepare_labels_for_mr' do
    it 'composes the labels string' do
      mr_labels = ['telemetry', 'telemetry::reviewed']

      expect(helper.prepare_labels_for_mr(mr_labels)).to eq('/label ~"telemetry" ~"telemetry::reviewed"')
    end

    it 'returns empty string for empty array' do
      expect(helper.prepare_labels_for_mr([])).to eq('')
    end
  end

  describe '#has_ci_changes?' do
    context 'when .gitlab/ci is changed' do
      it 'returns true' do
        expect(helper).to receive(:all_changed_files).and_return(%w[migration.rb .gitlab/ci/test.yml])

        expect(helper.has_ci_changes?).to be_truthy
      end
    end

    context 'when .gitlab-ci.yml is changed' do
      it 'returns true' do
        expect(helper).to receive(:all_changed_files).and_return(%w[migration.rb .gitlab-ci.yml])

        expect(helper.has_ci_changes?).to be_truthy
      end
    end

    context 'when neither .gitlab/ci/ or .gitlab-ci.yml is changed' do
      it 'returns false' do
        expect(helper).to receive(:all_changed_files).and_return(%w[migration.rb nested/.gitlab-ci.yml])

        expect(helper.has_ci_changes?).to be_falsey
      end
    end
  end
end

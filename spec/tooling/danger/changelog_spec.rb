# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/changelog'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Changelog do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { double('fake-project-helper', helper: fake_helper).tap { |h| h.class.include(Tooling::Danger::ProjectHelper) } }

  subject(:changelog) { fake_danger.new(helper: fake_helper) }

  before do
    allow(changelog).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#check_changelog_commit_categories' do
    context 'when all changelog commits are correct' do
      it 'does not produce any messages' do
        commit = double(:commit, message: "foo\nChangelog: fixed")

        allow(changelog).to receive(:changelog_commits).and_return([commit])

        expect(changelog).not_to receive(:fail)

        changelog.check_changelog_commit_categories
      end
    end

    context 'when a commit has an incorrect trailer' do
      it 'adds a message' do
        commit = double(:commit, message: "foo\nChangelog: foo", sha: '123')

        allow(changelog).to receive(:changelog_commits).and_return([commit])

        expect(changelog).to receive(:fail)

        changelog.check_changelog_commit_categories
      end
    end
  end

  describe '#check_changelog_trailer' do
    subject { changelog.check_changelog_trailer(commit) }

    context "when commit include a changelog trailer with an unknown category" do
      let(:commit) { double('commit', message: "Hello world\n\nChangelog: foo", sha: "abc123") }

      it { is_expected.to have_attributes(errors: ["Commit #{commit.sha} uses an invalid changelog category: foo"]) }
    end

    context 'when a commit uses the wrong casing for a trailer' do
      let(:commit) { double('commit', message: "Hello world\n\nchangelog: foo", sha: "abc123") }

      it { is_expected.to have_attributes(errors: ["The changelog trailer for commit #{commit.sha} must be `Changelog` (starting with a capital C), not `changelog`"]) }
    end

    described_class::CATEGORIES.each do |category|
      context "when commit include a changelog trailer with category set to '#{category}'" do
        let(:commit) { double('commit', message: "Hello world\n\nChangelog: #{category}", sha: "abc123") }

        it { is_expected.to have_attributes(errors: []) }
      end
    end
  end

  describe '#check_changelog_path' do
    let(:changelog_path) { 'changelog-path.yml' }
    let(:foss_change) { nil }
    let(:ee_change) { nil }
    let(:changelog_change) { nil }
    let(:changes) { changes_class.new([foss_change, ee_change, changelog_change].compact) }

    before do
      allow(changelog).to receive(:present?).and_return(true)
    end

    subject { changelog.check_changelog_path }

    context "when changelog is not present" do
      before do
        allow(changelog).to receive(:present?).and_return(false)
      end

      it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
    end

    context "with EE changes" do
      let(:ee_change) { change_class.new('ee/app/models/foo.rb', :added, :backend) }

      context "and a non-EE changelog, and changelog not required" do
        before do
          allow(changelog).to receive(:required?).and_return(false)
          allow(changelog).to receive(:ee_changelog?).and_return(false)
        end

        it { is_expected.to have_attributes(warnings: ["This MR changes code in `ee/`, but its Changelog commit is missing the [`EE: true` trailer](https://docs.gitlab.com/ee/development/changelog.html#gitlab-enterprise-changes). Consider adding it to your Changelog commits."]) }
      end

      context "and a EE changelog" do
        before do
          allow(changelog).to receive(:ee_changelog?).and_return(true)
        end

        it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }

        context "and there are DB changes" do
          let(:foss_change) { change_class.new('db/migrate/foo.rb', :added, :migration) }

          it { is_expected.to have_attributes(warnings: ["This MR has a Changelog commit with the `EE: true` trailer, but there are database changes which [requires](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry) the Changelog commit to not have the `EE: true` trailer. Consider removing the `EE: true` trailer from your commits."]) }
        end
      end
    end

    context "with no EE changes" do
      let(:foss_change) { change_class.new('app/models/foo.rb', :added, :backend) }

      context "and a non-EE changelog" do
        before do
          allow(changelog).to receive(:ee_changelog?).and_return(false)
        end

        it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
      end

      context "and a EE changelog" do
        before do
          allow(changelog).to receive(:ee_changelog?).and_return(true)
        end

        it { is_expected.to have_attributes(warnings: ["This MR has a Changelog commit for EE, but no code changes in `ee/`. Consider removing the `EE: true` trailer from your commits."]) }
      end
    end
  end

  describe '#required_reasons' do
    subject { changelog.required_reasons }

    context "added files contain a migration" do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

      it { is_expected.to include(:db_changes) }
    end

    context "removed files contains a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

      it { is_expected.to include(:feature_flag_removed) }
    end

    context "added files do not contain a migration" do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :frontend)]) }

      it { is_expected.to be_empty }
    end

    context "removed files do not contain a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :backend)]) }

      it { is_expected.to be_empty }
    end
  end

  describe '#required?' do
    subject { changelog.required? }

    context 'added files contain a migration' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

      it { is_expected.to be_truthy }
    end

    context "removed files contains a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

      it { is_expected.to be_truthy }
    end

    context 'added files do not contain a migration' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :frontend)]) }

      it { is_expected.to be_falsey }
    end

    context "removed files do not contain a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :backend)]) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#optional?' do
    let(:category_with_changelog) { :backend }
    let(:label_with_changelog) { 'frontend' }
    let(:category_without_changelog) { Tooling::Danger::Changelog::NO_CHANGELOG_CATEGORIES.first }
    let(:label_without_changelog) { Tooling::Danger::Changelog::NO_CHANGELOG_LABELS.first }

    subject { changelog.optional? }

    context 'when MR contains only categories requiring no changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :modified, category_without_changelog)]) }

      it 'is falsey' do
        is_expected.to be_falsy
      end
    end

    context 'when MR contains a label that require no changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :modified, category_with_changelog)]) }
      let(:mr_labels) { [label_with_changelog, label_without_changelog] }

      it 'is falsey' do
        is_expected.to be_falsy
      end
    end

    context 'when MR contains a category that require changelog and a category that require no changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :modified, category_with_changelog), change_class.new('foo', :modified, category_without_changelog)]) }

      context 'with no labels' do
        it 'is truthy' do
          is_expected.to be_truthy
        end
      end

      context 'with changelog label' do
        let(:mr_labels) { ['feature'] }

        it 'is truthy' do
          is_expected.to be_truthy
        end
      end

      context 'with no changelog label' do
        let(:mr_labels) { ['tooling'] }

        it 'is truthy' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#present?' do
    it 'returns true when a Changelog commit is present' do
      allow(changelog)
        .to receive(:valid_changelog_commits)
        .and_return([double(:commit)])

      expect(changelog).to be_present
    end

    it 'returns false when a Changelog commit is missing' do
      allow(changelog).to receive(:valid_changelog_commits).and_return([])

      expect(changelog).not_to be_present
    end
  end

  describe '#changelog_commits' do
    it 'returns the commits that include a Changelog trailer' do
      commit1 = double(:commit, message: "foo\nChangelog: fixed")
      commit2 = double(:commit, message: "bar\nChangelog: kittens")
      commit3 = double(:commit, message: 'testing')
      git = double(:git)

      allow(changelog).to receive(:git).and_return(git)
      allow(git).to receive(:commits).and_return([commit1, commit2, commit3])

      expect(changelog.changelog_commits).to eq([commit1, commit2])
    end
  end

  describe '#valid_changelog_commits' do
    it 'returns the commits with a valid Changelog trailer' do
      commit1 = double(:commit, message: "foo\nChangelog: fixed")
      commit2 = double(:commit, message: "bar\nChangelog: kittens")

      allow(changelog)
        .to receive(:changelog_commits)
        .and_return([commit1, commit2])

      expect(changelog.valid_changelog_commits).to eq([commit1])
    end
  end

  describe '#ee_changelog?' do
    it 'returns true when an EE changelog commit is present' do
      commit = double(:commit, message: "foo\nEE: true")

      allow(changelog).to receive(:changelog_commits).and_return([commit])

      expect(changelog.ee_changelog?).to eq(true)
    end

    it 'returns false when an EE changelog commit is missing' do
      commit = double(:commit, message: 'foo')

      allow(changelog).to receive(:changelog_commits).and_return([commit])

      expect(changelog.ee_changelog?).to eq(false)
    end
  end

  describe '#modified_text' do
    subject { changelog.modified_text }

    context 'when in CI context' do
      shared_examples 'changelog modified text' do |key|
        specify do
          expect(subject).to include('CHANGELOG.md was edited')
          expect(subject).to include('`Changelog` trailer')
          expect(subject).to include('`EE: true`')
        end
      end

      before do
        allow(fake_helper).to receive(:ci?).and_return(true)
      end

      context "when title is not changed from sanitization", :aggregate_failures do
        let(:mr_title) { 'Fake Title' }

        it_behaves_like 'changelog modified text'
      end

      context "when title needs sanitization", :aggregate_failures do
        let(:mr_title) { 'DRAFT: Fake Title' }

        it_behaves_like 'changelog modified text'
      end
    end

    context 'when in local context' do
      let(:mr_title) { 'Fake Title' }

      before do
        allow(fake_helper).to receive(:ci?).and_return(false)
      end

      specify do
        expect(subject).to include('CHANGELOG.md was edited')
        expect(subject).not_to include('`Changelog` trailer')
      end
    end
  end

  describe '#required_texts' do
    let(:mr_title) { 'Fake Title' }

    subject { changelog.required_texts }

    context 'when in CI context' do
      before do
        allow(fake_helper).to receive(:ci?).and_return(true)
      end

      shared_examples 'changelog required text' do |key|
        specify do
          expect(subject).to have_key(key)
          expect(subject[key]).to include('CHANGELOG missing')
          expect(subject[key]).to include('`Changelog` trailer')
        end
      end

      context 'with a new migration file' do
        let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

        context "when title is not changed from sanitization", :aggregate_failures do
          it_behaves_like 'changelog required text', :db_changes
        end

        context "when title needs sanitization", :aggregate_failures do
          let(:mr_title) { 'DRAFT: Fake Title' }

          it_behaves_like 'changelog required text', :db_changes
        end
      end

      context 'with a removed feature flag file' do
        let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

        it_behaves_like 'changelog required text', :feature_flag_removed
      end
    end

    context 'when in local context' do
      before do
        allow(fake_helper).to receive(:ci?).and_return(false)
      end

      shared_examples 'changelog required text' do |key|
        specify do
          expect(subject).to have_key(key)
          expect(subject[key]).to include('CHANGELOG missing')
          expect(subject[key]).not_to include('`Changelog` trailer')
        end
      end

      context 'with a new migration file' do
        let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

        context "when title is not changed from sanitization", :aggregate_failures do
          it_behaves_like 'changelog required text', :db_changes
        end

        context "when title needs sanitization", :aggregate_failures do
          let(:mr_title) { 'DRAFT: Fake Title' }

          it_behaves_like 'changelog required text', :db_changes
        end
      end

      context 'with a removed feature flag file' do
        let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

        it_behaves_like 'changelog required text', :feature_flag_removed
      end
    end
  end

  describe '#optional_text' do
    subject { changelog.optional_text }

    context 'when in CI context' do
      shared_examples 'changelog optional text' do |key|
        specify do
          expect(subject).to include('CHANGELOG missing')
          expect(subject).to include('`Changelog` trailer')
          expect(subject).to include('EE: true')
        end
      end

      before do
        allow(fake_helper).to receive(:ci?).and_return(true)
      end

      context "when title is not changed from sanitization", :aggregate_failures do
        let(:mr_title) { 'Fake Title' }

        it_behaves_like 'changelog optional text'
      end

      context "when title needs sanitization", :aggregate_failures do
        let(:mr_title) { 'DRAFT: Fake Title' }

        it_behaves_like 'changelog optional text'
      end
    end

    context 'when in local context' do
      let(:mr_title) { 'Fake Title' }

      before do
        allow(fake_helper).to receive(:ci?).and_return(false)
      end

      specify do
        expect(subject).to include('CHANGELOG missing')
      end
    end
  end
end

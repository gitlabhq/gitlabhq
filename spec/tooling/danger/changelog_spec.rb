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

  describe '#check_changelog_trailer' do
    subject { changelog.check_changelog_trailer(commit) }

    context "when commit doesn't include a changelog trailer" do
      let(:commit) { double('commit', message: "Hello world") }

      it { is_expected.to be_nil }
    end

    context "when commit include a changelog trailer with no category" do
      let(:commit) { double('commit', message: "Hello world\n\nChangelog:") }

      it { is_expected.to be_nil }
    end

    context "when commit include a changelog trailer with an unknown category" do
      let(:commit) { double('commit', message: "Hello world\n\nChangelog: foo", sha: "abc123") }

      it { is_expected.to have_attributes(errors: ["Commit #{commit.sha} uses an invalid changelog category: foo"]) }
    end

    described_class::CATEGORIES.each do |category|
      context "when commit include a changelog trailer with category set to '#{category}'" do
        let(:commit) { double('commit', message: "Hello world\n\nChangelog: #{category}", sha: "abc123") }

        it { is_expected.to have_attributes(errors: []) }
      end
    end
  end

  describe '#check_changelog_yaml' do
    let(:changelog_path) { 'ee/changelogs/unreleased/entry.yml' }
    let(:changes) { changes_class.new([change_class.new(changelog_path, :added, :changelog)]) }
    let(:yaml_title) { 'Fix changelog Dangerfile to convert MR IID to a string before comparison' }
    let(:yaml_merge_request) { 60899 }
    let(:mr_iid) { '60899' }
    let(:yaml_type) { 'fixed' }
    let(:yaml) do
      <<~YAML
      ---
      title: #{yaml_title}
      merge_request: #{yaml_merge_request}
      author:
      type: #{yaml_type}
      YAML
    end

    before do
      allow(changelog).to receive(:present?).and_return(true)
      allow(changelog).to receive(:changelog_path).and_return(changelog_path)
      allow(changelog).to receive(:read_file).with(changelog_path).and_return(yaml)
      allow(fake_helper).to receive(:security_mr?).and_return(false)
      allow(fake_helper).to receive(:mr_iid).and_return(mr_iid)
      allow(fake_helper).to receive(:cherry_pick_mr?).and_return(false)
      allow(fake_helper).to receive(:stable_branch?).and_return(false)
      allow(fake_helper).to receive(:html_link).with(changelog_path).and_return(changelog_path)
    end

    subject { changelog.check_changelog_yaml }

    context "when changelog is not present" do
      before do
        allow(changelog).to receive(:present?).and_return(false)
      end

      it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
    end

    context "when YAML is invalid" do
      let(:yaml) { '{ foo bar]' }

      it { is_expected.to have_attributes(errors: ["#{changelog_path} isn't valid YAML! #{described_class::SEE_DOC}"]) }
    end

    context "when a StandardError is raised" do
      before do
        allow(changelog).to receive(:read_file).and_raise(StandardError, "Fail!")
      end

      it { is_expected.to have_attributes(warnings: ["There was a problem trying to check the Changelog. Exception: StandardError - Fail!"]) }
    end

    context "when YAML title is nil" do
      let(:yaml_title) { '' }

      it { is_expected.to have_attributes(errors: ["`title` should be set, in #{changelog_path}! #{described_class::SEE_DOC}"]) }
    end

    context "when YAML type is nil" do
      let(:yaml_type) { '' }

      it { is_expected.to have_attributes(errors: ["`type` should be set, in #{changelog_path}! #{described_class::SEE_DOC}"]) }
    end

    context "when on a security MR" do
      let(:yaml_merge_request) { '' }

      before do
        allow(fake_helper).to receive(:security_mr?).and_return(true)
      end

      it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
    end

    context "when MR IID is empty" do
      before do
        allow(fake_helper).to receive(:mr_iid).and_return("")
      end

      it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
    end

    context "when YAML MR IID is empty" do
      let(:yaml_merge_request) { '' }

      context "and YAML includes a merge_request: line" do
        it { is_expected.to have_attributes(markdowns: [{ msg: format(described_class::SUGGEST_MR_COMMENT, mr_iid: fake_helper.mr_iid), file: changelog_path, line: 3 }]) }
      end

      context "and YAML does not include a merge_request: line" do
        let(:yaml) do
          <<~YAML
          ---
          title: #{yaml_title}
          author:
          type: #{yaml_type}
          YAML
        end

        it { is_expected.to have_attributes(messages: ["Consider setting `merge_request` to #{mr_iid} in #{changelog_path}. #{described_class::SEE_DOC}"]) }
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
        let(:changelog_change) { change_class.new('changelogs/unreleased/entry.yml', :added, :changelog) }

        before do
          allow(changelog).to receive(:required?).and_return(false)
        end

        it { is_expected.to have_attributes(warnings: ["This MR has a Changelog file outside `ee/`, but code changes in `ee/`. Consider moving the Changelog file into `ee/`."]) }
      end
    end

    context "with no EE changes" do
      let(:foss_change) { change_class.new('app/models/foo.rb', :added, :backend) }

      context "and a non-EE changelog" do
        let(:changelog_change) { change_class.new('changelogs/unreleased/entry.yml', :added, :changelog) }

        it { is_expected.to have_attributes(errors: [], warnings: [], markdowns: [], messages: []) }
      end

      context "and a EE changelog" do
        let(:changelog_change) { change_class.new('ee/changelogs/unreleased/entry.yml', :added, :changelog) }

        it { is_expected.to have_attributes(warnings: ["This MR has a Changelog file in `ee/`, but no code changes in `ee/`. Consider moving the Changelog file outside `ee/`."]) }
      end
    end
  end

  describe '#required_reasons' do
    subject { changelog.required_reasons }

    context "removed files contains a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

      it { is_expected.to include(:feature_flag_removed) }
    end

    context "removed files do not contain a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :backend)]) }

      it { is_expected.to be_empty }
    end

    context "added files contain a migration" do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

      it { is_expected.to be_empty }
    end
  end

  describe '#required?' do
    subject { changelog.required? }

    context "removed files contains a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

      it { is_expected.to be_truthy }
    end

    context "removed files do not contain a feature flag" do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :backend)]) }

      it { is_expected.to be_falsey }
    end

    context "added files contain a migration" do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :migration)]) }

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
    subject { changelog.present? }

    context 'added files contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :changelog)]) }

      it { is_expected.to be_truthy }
    end

    context 'added files do not contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :backend)]) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#ee_changelog?' do
    subject { changelog.ee_changelog? }

    context 'is ee changelog' do
      let(:changes) { changes_class.new([change_class.new('ee/changelogs/unreleased/entry.yml', :added, :changelog)]) }

      it { is_expected.to be_truthy }
    end

    context 'is not ee changelog' do
      let(:changes) { changes_class.new([change_class.new('changelogs/unreleased/entry.yml', :added, :changelog)]) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#changelog_path' do
    subject { changelog.changelog_path }

    context 'added files contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :changelog)]) }

      it { is_expected.to eq('foo') }
    end

    context 'added files do not contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :backend)]) }

      it { is_expected.to be_nil }
    end
  end

  describe '#modified_text' do
    subject { changelog.modified_text }

    context 'when in CI context' do
      shared_examples 'changelog modified text' do |key|
        specify do
          expect(subject).to include('CHANGELOG.md was edited')
          expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
          expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
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
        expect(subject).not_to include('bin/changelog')
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
          expect(subject[key]).to include('bin/changelog -m 1234 "Fake Title"')
          expect(subject[key]).not_to include('--ee')
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
          expect(subject[key]).not_to include('bin/changelog')
          expect(subject[key]).not_to include('--ee')
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
          expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
          expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
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
        expect(subject).not_to include('bin/changelog')
      end
    end
  end
end

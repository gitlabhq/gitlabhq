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

    context 'added files contain a migration' do
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

  describe '#found' do
    subject { changelog.found }

    context 'added files contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :changelog)]) }

      it { is_expected.to be_truthy }
    end

    context 'added files do not contain a changelog' do
      let(:changes) { changes_class.new([change_class.new('foo', :added, :backend)]) }

      it { is_expected.to eq(nil) }
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

  describe '#modified_text' do
    subject { changelog.modified_text }

    context "when title is not changed from sanitization", :aggregate_failures do
      let(:mr_title) { 'Fake Title' }

      specify do
        expect(subject).to include('CHANGELOG.md was edited')
        expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
        expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
      end
    end

    context "when title needs sanitization", :aggregate_failures do
      let(:mr_title) { 'DRAFT: Fake Title' }

      specify do
        expect(subject).to include('CHANGELOG.md was edited')
        expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
        expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
      end
    end
  end

  describe '#required_texts' do
    let(:mr_title) { 'Fake Title' }

    subject { changelog.required_texts }

    shared_examples 'changelog required text' do |key|
      specify do
        expect(subject).to have_key(key)
        expect(subject[key]).to include('CHANGELOG missing')
        expect(subject[key]).to include('bin/changelog -m 1234 "Fake Title"')
        expect(subject[key]).not_to include('--ee')
      end
    end

    context 'when in CI context' do
      before do
        allow(fake_helper).to receive(:ci?).and_return(true)
      end

      context 'with a removed feature flag file' do
        let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

        it_behaves_like 'changelog required text', :feature_flag_removed
      end
    end

    context 'with a removed feature flag file' do
      let(:changes) { changes_class.new([change_class.new('foo', :deleted, :feature_flag)]) }

      it_behaves_like 'changelog required text', :feature_flag_removed
    end
  end

  describe '#optional_text' do
    subject { changelog.optional_text }

    context "when title is not changed from sanitization", :aggregate_failures do
      let(:mr_title) { 'Fake Title' }

      specify do
        expect(subject).to include('CHANGELOG missing')
        expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
        expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
      end
    end

    context "when title needs sanitization", :aggregate_failures do
      let(:mr_title) { 'DRAFT: Fake Title' }

      specify do
        expect(subject).to include('CHANGELOG missing')
        expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
        expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
      end
    end
  end
end

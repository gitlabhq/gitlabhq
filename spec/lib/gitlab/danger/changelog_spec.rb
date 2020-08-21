# frozen_string_literal: true

require 'fast_spec_helper'
require_relative 'danger_spec_helper'

require 'gitlab/danger/changelog'

RSpec.describe Gitlab::Danger::Changelog do
  include DangerSpecHelper

  let(:added_files) { nil }
  let(:fake_git) { double('fake-git', added_files: added_files) }

  let(:mr_labels) { nil }
  let(:mr_json) { nil }
  let(:fake_gitlab) { double('fake-gitlab', mr_labels: mr_labels, mr_json: mr_json) }

  let(:changes_by_category) { nil }
  let(:sanitize_mr_title) { nil }
  let(:ee?) { false }
  let(:fake_helper) { double('fake-helper', changes_by_category: changes_by_category, sanitize_mr_title: sanitize_mr_title, ee?: ee?) }

  let(:fake_danger) { new_fake_danger.include(described_class) }

  subject(:changelog) { fake_danger.new(git: fake_git, gitlab: fake_gitlab, helper: fake_helper) }

  describe '#required?' do
    subject { changelog.required? }

    context 'added files contain a migration' do
      [
        'db/migrate/20200000000000_new_migration.rb',
        'db/post_migrate/20200000000000_new_migration.rb'
      ].each do |file_path|
        let(:added_files) { [file_path] }

        it { is_expected.to be_truthy }
      end
    end

    context 'added files do not contain a migration' do
      [
        'app/models/model.rb',
        'app/assets/javascripts/file.js'
      ].each do |file_path|
        let(:added_files) { [file_path] }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#optional?' do
    let(:category_with_changelog) { :backend }
    let(:label_with_changelog) { 'frontend' }
    let(:category_without_changelog) { Gitlab::Danger::Changelog::NO_CHANGELOG_CATEGORIES.first }
    let(:label_without_changelog) { Gitlab::Danger::Changelog::NO_CHANGELOG_LABELS.first }

    subject { changelog.optional? }

    context 'when MR contains only categories requiring no changelog' do
      let(:changes_by_category) { { category_without_changelog => nil } }
      let(:mr_labels) { [] }

      it 'is falsey' do
        is_expected.to be_falsy
      end
    end

    context 'when MR contains a label that require no changelog' do
      let(:changes_by_category) { { category_with_changelog => nil } }
      let(:mr_labels) { [label_with_changelog, label_without_changelog] }

      it 'is falsey' do
        is_expected.to be_falsy
      end
    end

    context 'when MR contains a category that require changelog and a category that require no changelog' do
      let(:changes_by_category) { { category_with_changelog => nil, category_without_changelog => nil } }
      let(:mr_labels) { [] }

      it 'is truthy' do
        is_expected.to be_truthy
      end
    end

    context 'when MR contains a category that require changelog and a category that require no changelog with changelog label' do
      let(:changes_by_category) { { category_with_changelog => nil, category_without_changelog => nil } }
      let(:mr_labels) { ['feature'] }

      it 'is truthy' do
        is_expected.to be_truthy
      end
    end

    context 'when MR contains a category that require changelog and a category that require no changelog with no changelog label' do
      let(:changes_by_category) { { category_with_changelog => nil, category_without_changelog => nil } }
      let(:mr_labels) { ['tooling'] }

      it 'is truthy' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#found' do
    subject { changelog.found }

    context 'added files contain a changelog' do
      [
        'changelogs/unreleased/entry.yml',
        'ee/changelogs/unreleased/entry.yml'
      ].each do |file_path|
        let(:added_files) { [file_path] }

        it { is_expected.to be_truthy }
      end
    end

    context 'added files do not contain a changelog' do
      [
        'app/models/model.rb',
        'app/assets/javascripts/file.js'
      ].each do |file_path|
        let(:added_files) { [file_path] }
        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#ee_changelog?' do
    subject { changelog.ee_changelog? }

    before do
      allow(changelog).to receive(:found).and_return(file_path)
    end

    context 'is ee changelog' do
      let(:file_path) { 'ee/changelogs/unreleased/entry.yml' }

      it { is_expected.to be_truthy }
    end

    context 'is not ee changelog' do
      let(:file_path) { 'changelogs/unreleased/entry.yml' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#modified_text' do
    let(:sanitize_mr_title) { 'Fake Title' }
    let(:mr_json) { { "iid" => 1234, "title" => sanitize_mr_title } }

    subject { changelog.modified_text }

    it do
      expect(subject).to include('CHANGELOG.md was edited')
      expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
      expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
    end
  end

  describe '#required_text' do
    let(:sanitize_mr_title) { 'Fake Title' }
    let(:mr_json) { { "iid" => 1234, "title" => sanitize_mr_title } }

    subject { changelog.required_text }

    it do
      expect(subject).to include('CHANGELOG missing')
      expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
      expect(subject).not_to include('--ee')
    end
  end

  describe 'optional_text' do
    let(:sanitize_mr_title) { 'Fake Title' }
    let(:mr_json) { { "iid" => 1234, "title" => sanitize_mr_title } }

    subject { changelog.optional_text }

    it do
      expect(subject).to include('CHANGELOG missing')
      expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
      expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
    end
  end
end

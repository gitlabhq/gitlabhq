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
  let(:ee?) { false }
  let(:fake_helper) { double('fake-helper', changes_by_category: changes_by_category, ee?: ee?) }

  let(:fake_danger) { new_fake_danger.include(described_class) }

  subject(:changelog) { fake_danger.new(git: fake_git, gitlab: fake_gitlab, helper: fake_helper) }

  describe '#needed?' do
    let(:category_with_changelog) { :backend }
    let(:label_with_changelog) { 'frontend' }
    let(:category_without_changelog) { Gitlab::Danger::Changelog::NO_CHANGELOG_CATEGORIES.first }
    let(:label_without_changelog) { Gitlab::Danger::Changelog::NO_CHANGELOG_LABELS.first }

    subject { changelog.needed? }

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
end

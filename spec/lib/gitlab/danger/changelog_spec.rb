# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require_relative 'danger_spec_helper'

require 'gitlab/danger/changelog'

describe Gitlab::Danger::Changelog do
  using RSpec::Parameterized::TableSyntax
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
    subject { changelog.needed? }

    [
      { docs: nil },
      { none: nil },
      { docs: nil, none: nil }
    ].each do |categories|
      let(:changes_by_category) { categories }

      it "is falsy when categories don't require a changelog" do
        is_expected.to be_falsy
      end
    end

    where(:categories, :labels) do
      { backend: nil }                             | %w[backend backstage]
      { frontend: nil, docs: nil }                 | ['ci-build']
      { engineering_productivity: nil, none: nil } | ['meta']
    end

    with_them do
      let(:changes_by_category) { categories }
      let(:mr_labels) { labels }

      it "is falsy when labels require no changelog" do
        is_expected.to be_falsy
      end
    end

    where(:categories, :labels) do
      { frontend: nil, docs: nil }                 | ['database::review pending', 'feature']
      { backend: nil }                             | ['backend', 'technical debt']
      { engineering_productivity: nil, none: nil } | ['frontend']
    end

    with_them do
      let(:changes_by_category) { categories }
      let(:mr_labels) { labels }

      it "is truthy when categories and labels require a changelog" do
        is_expected.to be_truthy
      end
    end
  end

  describe '#found' do
    subject { changelog.found }

    context 'added files contain a changelog' do
      [
        'changelogs/unreleased/entry.md',
        'ee/changelogs/unreleased/entry.md',
        'changelogs/unreleased-ee/entry.md',
        'ee/changelogs/unreleased-ee/entry.md'
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

  describe '#presented_no_changelog_labels' do
    subject { changelog.presented_no_changelog_labels }

    it 'returns the labels formatted' do
      is_expected.to eq('~backstage, ~ci-build, ~meta')
    end
  end

  describe '#sanitized_mr_title' do
    subject { changelog.sanitized_mr_title }

    [
      'WIP: My MR title',
      'My MR title'
    ].each do |mr_title|
      let(:mr_json) { { "title" => mr_title } }
      it { is_expected.to eq("My MR title") }
    end
  end

  describe '#ee_changelog?' do
    context 'is ee changelog' do
      [
        'changelogs/unreleased-ee/entry.md',
        'ee/changelogs/unreleased-ee/entry.md'
      ].each do |file_path|
        subject { changelog.ee_changelog?(file_path) }

        it { is_expected.to be_truthy }
      end
    end

    context 'is not ee changelog' do
      [
        'changelogs/unreleased/entry.md',
        'ee/changelogs/unreleased/entry.md'
      ].each do |file_path|
        subject { changelog.ee_changelog?(file_path) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#ce_port_changelog?' do
    where(:helper_ee?, :file_path, :expected) do
      true  | 'changelogs/unreleased-ee/entry.md'    | false
      true  | 'ee/changelogs/unreleased-ee/entry.md' | false
      false | 'changelogs/unreleased-ee/entry.md'    | false
      false | 'ee/changelogs/unreleased-ee/entry.md' | false
      true  | 'changelogs/unreleased/entry.md'       | true
      true  | 'ee/changelogs/unreleased/entry.md'    | true
      false | 'changelogs/unreleased/entry.md'       | false
      false | 'ee/changelogs/unreleased/entry.md'    | false
    end

    with_them do
      let(:ee?) { helper_ee? }
      subject { changelog.ce_port_changelog?(file_path) }

      it { is_expected.to eq(expected) }
    end
  end
end

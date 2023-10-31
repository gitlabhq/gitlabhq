# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Link do
  let(:release) { create(:release, project: project) }
  let(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:filepath).is_at_most(128) }

    context 'when url is invalid' do
      let(:link) { build(:release_link, url: 'hoge') }

      it 'will be invalid' do
        expect(link).to be_invalid
      end
    end

    context 'when duplicate name is added to a release' do
      let!(:link) { create(:release_link, name: 'alpha', release: release) }

      it 'raises an error' do
        expect do
          create(:release_link, name: 'alpha', release: release)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when duplicate url is added to a release' do
      let!(:link) { create(:release_link, url: 'http://gitlab.com', release: release) }

      it 'raises an error' do
        expect do
          create(:release_link, url: 'http://gitlab.com', release: release)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  context 'when duplicate filepath is added to a release' do
    let!(:link) { create(:release_link, filepath: '/binaries/gitlab-runner-linux-amd64', release: release) }

    it 'raises an error' do
      expect do
        create(:release_link, filepath: '/binaries/gitlab-runner-linux-amd64', release: release)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.sorted' do
    subject { described_class.sorted }

    let!(:link_1) { create(:release_link, name: 'alpha', release: release, created_at: 1.day.ago) }
    let!(:link_2) { create(:release_link, name: 'beta', release: release, created_at: 2.days.ago) }

    it 'returns a list of links by created_at order' do
      is_expected.to eq([link_1, link_2])
    end
  end

  describe '#internal?' do
    subject { link.internal? }

    let(:link) { build(:release_link, release: release, url: url) }
    let(:url) { "#{project.web_url}/-/jobs/140463678/artifacts/download" }

    it { is_expected.to be_truthy }

    context 'when link does not include project web url' do
      let(:url) { 'https://google.com/-/jobs/140463678/artifacts/download' }

      it { is_expected.to be_falsy }
    end
  end

  describe 'supported protocols' do
    where(:protocol) do
      %w[http https ftp]
    end

    with_them do
      let(:link) { build(:release_link, url: protocol + '://assets.com/download') }

      it 'will be valid' do
        expect(link).to be_valid
      end
    end
  end

  describe 'unsupported protocol' do
    context 'for torrent' do
      let(:link) { build(:release_link, url: 'torrent://assets.com/download') }

      it 'will be invalid' do
        expect(link).to be_invalid
      end
    end
  end

  describe 'when filepath is greater than max length' do
    let!(:invalid_link) { build(:release_link, filepath: 'x' * (Releases::Link::FILEPATH_MAX_LENGTH + 1), release: release) }

    it 'will not execute regex' do
      invalid_link.filepath_format_valid?

      expect(invalid_link.errors[:filepath].size).to eq(1)
      expect(invalid_link.errors[:filepath].first).to start_with("is too long")
    end
  end

  describe 'FILEPATH_REGEX with table' do
    using RSpec::Parameterized::TableSyntax

    let(:link) { build(:release_link) }

    where(:reason, :filepath, :result) do
      'cannot contain `//`'         | '/https//www.example.com'     | be_invalid
      'cannot start with `//`'      | '//www.example.com'           | be_invalid
      'cannot contain a `?`'        | '/example.com/?stuff=true'    | be_invalid
      'cannot contain a `:`'        | '/example:5000'               | be_invalid
      'cannot end in a `-`'         | '/binaries/awesome-app.dmg-'  | be_invalid
      'cannot end in a `.`'         | '/binaries/awesome-app.dmg.'  | be_invalid
      'cannot end in a `_`'         | '/binaries/awesome-app.dmg_'  | be_invalid
      'cannot start with a `.`'     | '.binaries/awesome-app.dmg'   | be_invalid
      'cannot start with a `-`'     | '-binaries/awesome-app.dmg'   | be_invalid
      'cannot start with a `_`'     | '_binaries/awesome-app.dmg'   | be_invalid
      'cannot start with a number'  | '3binaries/awesome-app.dmg'   | be_invalid
      'cannot start with a letter'  | 'binaries/awesome-app.dmg'    | be_invalid
      'cannot contain accents'      | '/binarïes/âwésome-app.dmg'   | be_invalid
      'can end in a character'      | '/binaries/awesome-app.dmg'   | be_valid
      'can end in a number'         | '/binaries/awesome-app-1'     | be_valid
      'can contain one or more dots, dashes or underscores' | '/sub_tr__ee.ex..ample-2--1/v99.com' | be_valid
      'can contain multiple non-sequential slashes' | '/example.com/path/to/file.exe' | be_valid
      'can be nil' | nil | be_valid
    end

    with_them do
      specify do
        link.filepath = filepath
        expect(link).to result
      end
    end
  end
end

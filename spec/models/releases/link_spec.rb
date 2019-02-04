# frozen_string_literal: true

require 'spec_helper'

describe Releases::Link do
  let(:release) { create(:release, project: project) }
  let(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:name) }

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

  describe '#external?' do
    subject { link.external? }

    let(:link) { build(:release_link, release: release, url: url) }
    let(:url) { 'https://google.com/-/jobs/140463678/artifacts/download' }

    it { is_expected.to be_truthy }
  end
end

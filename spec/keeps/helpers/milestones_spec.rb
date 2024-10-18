# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/milestones'

RSpec.describe Keeps::Helpers::Milestones, feature_category: :tooling do
  let(:milestones_yaml) do
    <<~YAML
    - version: '17.0'
      date: '2024-05-16'
      manager_americas:
        - Some Manager
    - version: '16.11'
      date: '2024-04-18'
      manager_apac_emea:
        - Some Other Manager
    - version: '16.10'
      date: '2024-03-21'
    - version: '16.9'
      date: '2024-02-15'
    - version: '16.8'
      date: '2024-01-18'
    - version: '16.7'
      date: '2023-12-21'
    - version: '16.6'
      date: '2023-11-16'
    - version: '16.5'
      date: '2023-10-22'
    - version: '16.4'
      date: '2023-09-22'
    - version: '16.3'
      date: '2023-08-22'
    - version: '16.2'
      date: '2023-07-22'
    - version: '16.1'
      date: '2023-06-22'
    - version: '16.0'
      date: '2023-05-22'
    - version: '15.11'
      date: '2023-04-22'
    - version: '15.10'
      date: '2023-03-22'
    - version: '15.9'
      date: '2023-02-22'
    - version: '15.8'
      date: '2023-01-22'
    - version: '15.7'
      date: '2022-12-22'
    - version: '15.6'
      date: '2022-11-22'
    - version: '15.5'
      date: '2022-10-22'
    - version: '15.4'
      date: '2022-09-22'
    - version: '15.3'
      date: '2022-08-22'
    - version: '15.2'
      date: '2022-07-22'
    - version: '15.1'
      date: '2022-06-22'
    - version: '15.0'
      date: '2022-05-22'
    - version: '14.10'
      date: '2022-04-22'
    - version: '14.9'
      date: '2022-03-22'
    YAML
  end

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(File.expand_path('../../../VERSION', __dir__)).and_return('16.9.0-pre')
    stub_request(:get, described_class::RELEASES_YML_URL).to_return(status: 200, body: milestones_yaml)
  end

  describe '#past_milestone' do
    let(:milestone) { '16.9' }

    subject(:past_milestone) { described_class.new.past_milestone(milestones_ago: milestones_ago) }

    context 'when asking 1 milestone ago' do
      let(:milestones_ago) { 1 }

      it { is_expected.to eq('16.8') }
    end

    context 'when asking 9 milestones ago' do
      let(:milestones_ago) { 9 }

      it { is_expected.to eq('16.0') }
    end

    context 'when asking 10 milestones ago' do
      let(:milestones_ago) { 10 }

      it { is_expected.to eq('15.11') }
    end

    context 'when asking 22 milestones ago' do
      let(:milestones_ago) { 22 }

      it { is_expected.to eq('14.10') }
    end
  end

  describe '#before_cuttoff?' do
    let(:milestone) { '16.9' }

    subject(:before_cuttoff) { described_class.new.before_cuttoff?(milestone: milestone, milestones_ago: 12) }

    it { is_expected.to eq(false) }

    context 'when milestone is before cuttoff' do
      let(:milestone) { '15.8' }

      it { is_expected.to eq(true) }
    end

    context 'when milestone is more than 2 major versions before cuttoff' do
      let(:milestone) { '14.10' }

      subject(:before_cuttoff) { described_class.new.before_cuttoff?(milestone: milestone, milestones_ago: 21) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#upcoming_milestone', time_travel_to: '2024-04-17' do
    subject(:upcoming_milestones) { described_class.new.upcoming_milestones }

    it 'returns milestones in the future' do
      expected_milestones = [
        described_class::Milestone.new(version: '16.11', date: '2024-04-18'),
        described_class::Milestone.new(version: '17.0', date: '2024-05-16')
      ]

      expect(upcoming_milestones).to contain_exactly(*expected_milestones)
    end
  end
end

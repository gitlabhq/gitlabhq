# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::TimeTrackingExtractor, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:extractor) { described_class.new(project, user) }

  describe '#extract_time_spent' do
    it 'returns an empty hash when message is nil' do
      expect(extractor.extract_time_spent(nil)).to eq({})
    end

    it 'returns an empty hash when message contains no time tracking information' do
      expect(extractor.extract_time_spent('No time tracking here')).to eq({})
    end

    it 'returns an empty hash when message contains time tracking information but no issue references' do
      expect(extractor.extract_time_spent('Working on something @1h30m')).to eq({})
    end

    context 'when message contains time tracking information and issue references' do
      let(:message) { "Fix bug in #{issue.to_reference} @2h30m" }

      it 'returns a hash with the issue and time spent' do
        expected_time = Gitlab::TimeTrackingFormatter.parse('2h30m')
        expect(extractor.extract_time_spent(message)).to eq({ issue => expected_time })
      end
    end

    context 'when message contains multiple time tracking markers' do
      let(:message) { "Fix bug in #{issue.to_reference} @2h30m and also @1d" }

      it 'uses the first valid time tracking marker found' do
        expected_time = Gitlab::TimeTrackingFormatter.parse('2h30m')
        expect(extractor.extract_time_spent(message)).to eq({ issue => expected_time })
      end
    end

    context 'when message references multiple issues' do
      let_it_be(:issue2) { create(:issue, project: project) }
      let(:message) { "Fix bugs in #{issue.to_reference} and #{issue2.to_reference} @3h" }

      it 'returns a hash with all issues and their time spent' do
        expected_time = Gitlab::TimeTrackingFormatter.parse('3h')
        expect(extractor.extract_time_spent(message)).to eq({
          issue => expected_time,
          issue2 => expected_time
        })
      end
    end

    context 'with various time formats' do
      let(:test_cases) do
        {
          '@1h' => '1h',
          '@2h30m' => '2h30m',
          '@1d2h' => '1d2h',
          '@30m' => '30m',
          '@1mo' => '1mo',
          '@2mo1d' => '2mo1d'
        }
      end

      it 'correctly parses different time formats' do
        test_cases.each do |input, expected|
          message = "Fix bug in #{issue.to_reference} #{input}"
          expected_time = Gitlab::TimeTrackingFormatter.parse(expected)

          expect(extractor.extract_time_spent(message)).to eq({ issue => expected_time })
        end
      end
    end

    context 'when time format is invalid' do
      let(:message) { "Fix bug in #{issue.to_reference} @invalid" }

      it 'returns an empty hash' do
        expect(extractor.extract_time_spent(message)).to eq({})
      end
    end

    context 'when work items are referenced' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }

      it 'includes work items in the results' do
        message = "Fix bug in #{work_item.to_reference} @2h"
        expected_time = Gitlab::TimeTrackingFormatter.parse('2h')

        result = extractor.extract_time_spent(message)
        expect(result.each_key.first.id).to eq(work_item.id)
        expect(result.each_key.first.to_reference).to eq(work_item.to_reference)
        expect(result.each_value.first).to eq(expected_time)
      end
    end
  end
end

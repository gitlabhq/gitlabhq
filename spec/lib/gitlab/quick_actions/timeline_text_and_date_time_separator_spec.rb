# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QuickActions::TimelineTextAndDateTimeSeparator do
  subject(:timeline_text_and_datetime_separator) { described_class }

  shared_examples 'arg line with invalid parameters' do
    it 'returns nil' do
      expect(timeline_text_and_datetime_separator.new(invalid_arg).execute).to eq(nil)
    end
  end

  shared_examples 'arg line with valid parameters' do
    it 'returns text and date time array' do
      freeze_time do
        expect(timeline_text_and_datetime_separator.new(valid_arg).execute).to eq(expected_response)
      end
    end
  end

  describe 'execute' do
    context 'with invalid parameters in arg line' do
      context 'with empty arg line' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { '' }
        end
      end

      context 'with invalid date' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { 'timeline comment | 2022-13-13 09:30' }
        end

        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { 'timeline comment | 2022-09/09 09:30' }
        end

        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { 'timeline comment | 2022-09.09 09:30' }
        end
      end

      context 'with invalid time' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { 'timeline comment | 2022-11-13 29:30' }
        end
      end

      context 'when date is invalid in arg line' do
        let(:invalid_arg) { 'timeline comment | wrong data type' }

        it 'return current date' do
          timeline_args = timeline_text_and_datetime_separator.new(invalid_arg).execute

          expect(timeline_args).to be_an_instance_of(Array)
          expect(timeline_args.first).to eq('timeline comment')
          expect(timeline_args.second).to match(Gitlab::QuickActions::TimelineTextAndDateTimeSeparator::DATETIME_REGEX)
        end
      end
    end

    context 'with valid parameters' do
      context 'when only timeline text present in arg line' do
        it_behaves_like 'arg line with valid parameters' do
          let(:timeline_text) { 'timeline comment' }
          let(:valid_arg) { timeline_text }
          let(:date) { DateTime.current.strftime("%Y-%m-%d %H:%M:00 UTC") }
          let(:expected_response) { [timeline_text, date] }
        end
      end

      context 'when only timeline text and time present in arg line' do
        it_behaves_like 'arg line with valid parameters' do
          let(:timeline_text) { 'timeline comment' }
          let(:date) { '09:30' }
          let(:valid_arg) { "#{timeline_text} | #{date}" }
          let(:parsed_date) { DateTime.parse(date) }
          let(:expected_response) { [timeline_text, parsed_date] }
        end
      end

      context 'when timeline text and date is present in arg line' do
        it_behaves_like 'arg line with valid parameters' do
          let(:timeline_text) { 'timeline comment' }
          let(:date) { '2022-06-05 09:30' }
          let(:valid_arg) { "#{timeline_text} | #{date}" }
          let(:parsed_date) { DateTime.parse(date) }
          let(:expected_response) { [timeline_text, parsed_date] }
        end
      end
    end
  end
end

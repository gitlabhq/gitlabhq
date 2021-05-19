# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QuickActions::SpendTimeAndDateSeparator do
  subject { described_class }

  shared_examples 'arg line with invalid parameters' do
    it 'return nil' do
      expect(subject.new(invalid_arg).execute).to eq(nil)
    end
  end

  shared_examples 'arg line with valid parameters' do
    it 'return time and date array' do
      freeze_time do
        expect(subject.new(valid_arg).execute).to eq(expected_response)
      end
    end
  end

  describe '#execute' do
    context 'invalid paramenter in arg line' do
      context 'empty arg line' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { '' }
        end
      end

      context 'future date in arg line' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { '10m 6023-02-02' }
        end
      end

      context 'unparseable date(invalid mixes of delimiters)' do
        it_behaves_like 'arg line with invalid parameters' do
          let(:invalid_arg) { '10m 2017.02-02' }
        end
      end

      context 'trash in arg line' do
        let(:invalid_arg) { 'dfjkghdskjfghdjskfgdfg' }

        it 'return nil as time value' do
          time_date_response = subject.new(invalid_arg).execute

          expect(time_date_response).to be_an_instance_of(Array)
          expect(time_date_response.first).to eq(nil)
        end
      end
    end

    context 'only time present in arg line' do
      it_behaves_like 'arg line with valid parameters' do
        let(:valid_arg) { '2m 3m 5m 1h' }
        let(:time) { Gitlab::TimeTrackingFormatter.parse(valid_arg) }
        let(:date) { DateTime.current }
        let(:expected_response) { [time, date] }
      end
    end

    context 'simple time with date in arg line' do
      it_behaves_like 'arg line with valid parameters' do
        let(:raw_time) { '10m' }
        let(:raw_date) { '2016-02-02' }
        let(:valid_arg) { "#{raw_time} #{raw_date}" }
        let(:date) { Date.parse(raw_date) }
        let(:time) { Gitlab::TimeTrackingFormatter.parse(raw_time) }
        let(:expected_response) { [time, date] }
      end
    end

    context 'composite time with date in arg line' do
      it_behaves_like 'arg line with valid parameters' do
        let(:raw_time) { '2m 10m 1h 3d' }
        let(:raw_date) { '2016/02/02' }
        let(:valid_arg) { "#{raw_time} #{raw_date}" }
        let(:date) { Date.parse(raw_date) }
        let(:time) { Gitlab::TimeTrackingFormatter.parse(raw_time) }
        let(:expected_response) { [time, date] }
      end
    end
  end
end

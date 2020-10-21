# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::ReindexAction, '.keep_track_of' do
  let(:index) { double('index', identifier: 'public.something', ondisk_size_bytes: 10240, reload: nil) }
  let(:size_after) { 512 }

  it 'yields to the caller' do
    expect { |b| described_class.keep_track_of(index, &b) }.to yield_control
  end

  def find_record
    described_class.find_by(index_identifier: index.identifier)
  end

  it 'creates the record with a start time and updates its end time' do
    freeze_time do
      described_class.keep_track_of(index) do
        expect(find_record.action_start).to be_within(1.second).of(Time.zone.now)

        travel(10.seconds)
      end

      duration = find_record.action_end - find_record.action_start

      expect(duration).to be_within(1.second).of(10.seconds)
    end
  end

  it 'creates the record with its status set to :started and updates its state to :finished' do
    described_class.keep_track_of(index) do
      expect(find_record).to be_started
    end

    expect(find_record).to be_finished
  end

  it 'creates the record with the indexes start size and updates its end size' do
    described_class.keep_track_of(index) do
      expect(find_record.ondisk_size_bytes_start).to eq(index.ondisk_size_bytes)

      expect(index).to receive(:reload).once
      allow(index).to receive(:ondisk_size_bytes).and_return(size_after)
    end

    expect(find_record.ondisk_size_bytes_end).to eq(size_after)
  end

  context 'in case of errors' do
    it 'sets the state to failed' do
      expect do
        described_class.keep_track_of(index) do
          raise 'something went wrong'
        end
      end.to raise_error(/something went wrong/)

      expect(find_record).to be_failed
    end

    it 'records the end time' do
      freeze_time do
        expect do
          described_class.keep_track_of(index) do
            raise 'something went wrong'
          end
        end.to raise_error(/something went wrong/)

        expect(find_record.action_end).to be_within(1.second).of(Time.zone.now)
      end
    end

    it 'records the resulting index size' do
      expect(index).to receive(:reload).once
      allow(index).to receive(:ondisk_size_bytes).and_return(size_after)

      expect do
        described_class.keep_track_of(index) do
          raise 'something went wrong'
        end
      end.to raise_error(/something went wrong/)

      expect(find_record.ondisk_size_bytes_end).to eq(size_after)
    end
  end
end

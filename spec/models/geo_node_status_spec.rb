require 'spec_helper'

describe GeoNodeStatus, model: true do
  subject { described_class.new }

  describe '#healthy?' do
    context 'when health is blank' do
      it 'returns true' do
        subject.health = ''

        expect(subject.healthy?).to eq true
      end
    end

    context 'when health is present' do
      it 'returns false' do
        subject.health = 'something went wrong'

        expect(subject.healthy?).to eq false
      end
    end
  end

  describe '#health' do
    it 'delegates to the HealthCheck' do
      subject.health = nil

      expect(HealthCheck::Utils).to receive(:process_checks).with(['geo']).once

      subject.health
    end
  end

  describe '#lfs_objects_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.lfs_objects_count = 0
      subject.lfs_objects_synced_count = 0

      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.lfs_objects_count = 4
      subject.lfs_objects_synced_count = 1

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.repositories_count = 0
      subject.repositories_synced_count = 0

      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.repositories_count = 4
      subject.repositories_synced_count = 1

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end

  context 'when no values are available' do
    it 'returns 0 for each attribute' do
      subject.lfs_objects_count = nil
      subject.lfs_objects_synced_count = nil
      subject.repositories_count = nil
      subject.repositories_synced_count = nil
      subject.repositories_failed_count = nil

      expect(subject.repositories_count).to be_zero
      expect(subject.repositories_synced_count).to be_zero
      expect(subject.repositories_synced_in_percentage).to be_zero
      expect(subject.repositories_failed_count).to be_zero
      expect(subject.lfs_objects_count).to be_zero
      expect(subject.lfs_objects_synced_count).to be_zero
      expect(subject.lfs_objects_synced_in_percentage).to be_zero
    end
  end
end

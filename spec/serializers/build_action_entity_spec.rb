require 'spec_helper'

describe BuildActionEntity do
  let(:job) { create(:ci_build, name: 'test_job') }
  let(:request) { double('request') }

  let(:entity) do
    described_class.new(job, request: spy('request'))
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains original job name' do
      expect(subject[:name]).to eq 'test_job'
    end

    it 'contains path to the action play' do
      expect(subject[:path]).to include "jobs/#{job.id}/play"
    end

    it 'contains whether it is playable' do
      expect(subject[:playable]).to eq job.playable?
    end

    context 'when job is scheduled' do
      let(:job) { create(:ci_build, :scheduled) }

      it 'returns scheduled' do
        expect(subject[:scheduled]).to be_truthy
      end

      it 'returns scheduled_at' do
        expect(subject[:scheduled_at]).to eq(job.scheduled_at)
      end

      it 'returns unschedule path' do
        expect(subject[:unschedule_path]).to include "jobs/#{job.id}/unschedule"
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqVersioning::Worker do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      # ApplicationWorker includes Gitlab::SidekiqVersioning::Worker
      include ApplicationWorker

      version 2
    end
  end

  describe '.version' do
    context 'when called with an argument' do
      it 'sets the version option' do
        worker.version 3

        expect(worker.get_sidekiq_options['version']).to eq(3)
      end
    end

    context 'when called without an argument' do
      it 'returns the version option' do
        worker.sidekiq_options version: 3

        expect(worker.version).to eq(3)
      end
    end
  end

  describe '#job_version' do
    let(:job) { worker.new }

    context 'when job_version is not set' do
      it 'returns latest version' do
        expect(job.job_version).to eq(2)
      end
    end

    context 'when job_version is set' do
      it 'returns the set version' do
        job.job_version = 0

        expect(job.job_version).to eq(0)
      end
    end
  end
end

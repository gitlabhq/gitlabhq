# frozen_string_literal: true

require 'spec_helper'

describe Ci::DagJobEntity do
  let_it_be(:request) { double(:request) }

  let(:job) { create(:ci_build, name: 'dag_job') }
  let(:entity) { described_class.new(job, request: request) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains the name' do
      expect(subject[:name]).to eq 'dag_job'
    end

    context 'when job is stage scheduled' do
      it 'does not expose needs' do
        expect(subject).not_to include(:needs)
      end
    end

    context 'when job is dag scheduled' do
      context 'when job has needs' do
        let(:job) { create(:ci_build, scheduling_type: 'dag') }
        let!(:need) { create(:ci_build_need, build: job, name: 'compile') }

        it 'exposes the array of needs' do
          expect(subject[:needs]).to eq ['compile']
        end
      end

      context 'when job has empty needs' do
        let(:job) { create(:ci_build, scheduling_type: 'dag') }

        it 'exposes an empty array of needs' do
          expect(subject[:needs]).to eq []
        end
      end
    end
  end
end

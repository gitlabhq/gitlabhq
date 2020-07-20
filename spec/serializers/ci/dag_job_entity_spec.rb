# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DagJobEntity do
  let_it_be(:request) { double(:request) }

  let(:job) { create(:ci_build, name: 'dag_job') }
  let(:entity) { described_class.new(job, request: request) }

  describe '#as_json' do
    subject { entity.as_json }

    RSpec.shared_examples "matches schema" do
      it "matches schema" do
        expect(subject.to_json).to match_schema('entities/dag_job')
      end
    end

    it 'contains the name' do
      expect(subject[:name]).to eq 'dag_job'
    end

    it_behaves_like "matches schema"

    context 'when job is stage scheduled' do
      it 'contains the name scheduling_type' do
        expect(subject[:scheduling_type]).to eq 'stage'
      end

      it 'does not expose needs' do
        expect(subject).not_to include(:needs)
      end

      it_behaves_like "matches schema"
    end

    context 'when job is dag scheduled' do
      let(:job) { create(:ci_build, scheduling_type: 'dag') }

      it 'contains the name scheduling_type' do
        expect(subject[:scheduling_type]).to eq 'dag'
      end

      it_behaves_like "matches schema"

      context 'when job has needs' do
        let!(:need) { create(:ci_build_need, build: job, name: 'compile') }

        it 'exposes the array of needs' do
          expect(subject[:needs]).to eq ['compile']
        end

        it_behaves_like "matches schema"
      end

      context 'when job has empty needs' do
        it 'exposes an empty array of needs' do
          expect(subject[:needs]).to eq []
        end

        it_behaves_like "matches schema"
      end
    end
  end
end

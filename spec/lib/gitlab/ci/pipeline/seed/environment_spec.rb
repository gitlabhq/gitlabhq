# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Environment do
  let_it_be(:project) { create(:project) }
  let(:job) { build(:ci_build, project: project) }
  let(:seed) { described_class.new(job) }
  let(:attributes) { {} }

  before do
    job.assign_attributes(**attributes)
  end

  describe '#to_resource' do
    subject { seed.to_resource }

    context 'when job has environment attribute' do
      let(:attributes) do
        {
          environment: 'production',
          options: { environment: { name: 'production' } }
        }
      end

      it 'returns a persisted environment object' do
        expect(subject).to be_a(Environment)
        expect(subject).to be_persisted
        expect(subject.project).to eq(project)
        expect(subject.name).to eq('production')
      end

      context 'when environment has already existed' do
        let!(:environment) { create(:environment, project: project, name: 'production') }

        it 'returns the existing environment object' do
          expect(subject).to be_persisted
          expect(subject).to eq(environment)
        end
      end
    end
  end
end

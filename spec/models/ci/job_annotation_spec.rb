# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobAnnotation, feature_category: :job_artifacts do
  let_it_be_with_refind(:job) { create(:ci_build, :success) }

  describe 'validations' do
    let!(:annotations) { create(:ci_job_annotation, job: job) }

    it { is_expected.to belong_to(:job).class_name('Ci::Build').inverse_of(:job_annotations) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '.create' do
    context 'when JSON data is valid' do
      subject do
        job.job_annotations.create!(
          name: 'external',
          data: [{ external_link: { label: 'Example', url: 'https://example.com/' } }]
        )
      end

      it 'creates the object' do
        expect(subject).to be_a(described_class)
        expect(subject.data).to contain_exactly(a_hash_including('external_link' =>
          a_hash_including('label' => 'Example', 'url' => 'https://example.com/')))
      end
    end

    context 'when JSON data is invalid' do
      subject { job.job_annotations.create!(name: 'external', data: [{ invalid: 'invalid' }]) }

      it 'throws an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when there are more than 1000 JSON entries' do
      subject { job.job_annotations.create!(data: [{ external_link: { label: 'Example', url: 'https://example.com/' } }] * 1001) }

      it 'throws an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'partitioning' do
    context 'with job' do
      before do
        job.partition_id = 123
      end

      let(:annotation) { build(:ci_job_annotation, job: job) }

      it 'copies the partition_id from job' do
        expect { annotation.valid? }.to change { annotation.partition_id }.to(123)
      end

      context 'when it is already set' do
        let(:annotation) { build(:ci_job_annotation, job: job, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { annotation.valid? }.not_to change { annotation.partition_id }
        end
      end
    end
  end
end

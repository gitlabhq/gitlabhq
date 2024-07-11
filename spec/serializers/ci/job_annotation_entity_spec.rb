# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobAnnotationEntity, feature_category: :job_artifacts do
  let(:entity) { described_class.new(annotation) }

  let(:job) { build(:ci_build) }
  let(:annotation) do
    build(:ci_job_annotation, job: job, name: 'external_links', data:
      [{ external_link: { label: 'URL', url: 'https://example.com/' } }])
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains valid name' do
      expect(subject[:name]).to eq 'external_links'
    end

    it 'contains external links' do
      expect(subject[:data]).to include(a_hash_including(
        'external_link' => a_hash_including(
          'label' => 'URL',
          'url' => 'https://example.com/'
        )
      ))
    end
  end
end

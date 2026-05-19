# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Enums::Ci::JobArtifact, feature_category: :job_artifacts do
  describe '.file_type' do
    subject { described_class.file_type }

    it { is_expected.to include(environment_key: 35) }
  end

  describe 'DEFAULT_FILE_NAMES' do
    subject { described_class::DEFAULT_FILE_NAMES }

    it { is_expected.to include(environment_key: 'environment_key.txt') }
  end

  describe 'REPORT_TYPES' do
    subject { described_class::REPORT_TYPES }

    it { is_expected.to include(environment_key: :raw) }
  end

  describe 'DOWNLOADABLE_TYPES' do
    subject { described_class::DOWNLOADABLE_TYPES }

    it { is_expected.not_to include('environment_key') }
  end
end

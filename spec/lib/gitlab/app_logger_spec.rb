# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppLogger, feature_category: :shared do
  subject { described_class }

  specify { expect(described_class.primary_logger).to be Gitlab::AppJsonLogger }

  context 'when UNSTRUCTURED_RAILS_LOG is enabled' do
    before do
      stub_env('UNSTRUCTURED_RAILS_LOG', 'true')
    end

    it 'builds two Logger instances' do
      expect(Gitlab::Logger).to receive(:new).and_call_original
      expect(Gitlab::JsonLogger).to receive(:new).and_call_original

      subject.info('Hello World!')
    end

    it 'logs info to multiple loggers' do
      expect_any_instance_of(Gitlab::AppTextLogger).to receive(:info).and_call_original
      expect_any_instance_of(Gitlab::AppJsonLogger).to receive(:info).and_call_original

      subject.info('Hello World!')
    end
  end

  context 'when UNSTRUCTURED_RAILS_LOG is disabled' do
    it 'logs info to only the AppJsonLogger' do
      expect_any_instance_of(Gitlab::AppTextLogger).not_to receive(:info).and_call_original
      expect_any_instance_of(Gitlab::AppJsonLogger).to receive(:info).and_call_original

      subject.info('Hello World!')
    end
  end
end

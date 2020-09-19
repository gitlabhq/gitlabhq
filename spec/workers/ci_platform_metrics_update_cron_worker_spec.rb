# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CiPlatformMetricsUpdateCronWorker, type: :worker do
  describe '#perform' do
    subject { described_class.new.perform }

    it 'inserts new platform metrics' do
      expect(CiPlatformMetric).to receive(:insert_auto_devops_platform_targets!).and_call_original

      subject
    end
  end
end

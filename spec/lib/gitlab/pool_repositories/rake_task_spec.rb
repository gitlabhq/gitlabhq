# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::RakeTask, feature_category: :source_code_management do
  describe '.logger' do
    context 'when in development environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      end

      it 'returns a BroadcastLogger combining stdout and Rails logger' do
        logger = described_class.logger

        expect(logger).to be_a(ActiveSupport::BroadcastLogger)
      end
    end

    context 'when in production environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      it 'returns a BroadcastLogger combining stdout and Rails logger' do
        logger = described_class.logger

        expect(logger).to be_a(ActiveSupport::BroadcastLogger)
      end
    end

    context 'when in other environments' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('staging'))
      end

      it 'returns Rails logger' do
        logger = described_class.logger

        expect(logger).to be(Rails.logger)
      end
    end
  end
end

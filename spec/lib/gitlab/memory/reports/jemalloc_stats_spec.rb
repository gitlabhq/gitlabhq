# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reports::JemallocStats do
  subject(:jemalloc_stats) { described_class.new }

  let(:writer) { StringIO.new }

  describe '.run' do
    context 'when :report_jemalloc_stats ops FF is enabled' do
      it 'dumps jemalloc stats to the given writer' do
        expect(Gitlab::Memory::Jemalloc).to receive(:dump_stats).with(writer)

        jemalloc_stats.run(writer)
      end
    end

    context 'when :report_jemalloc_stats ops FF is disabled' do
      before do
        stub_feature_flags(report_jemalloc_stats: false)
      end

      it 'does not run the report' do
        expect(Gitlab::Memory::Jemalloc).not_to receive(:dump_stats)

        jemalloc_stats.run(writer)
      end
    end
  end

  describe '.active?' do
    subject(:active) { jemalloc_stats.active? }

    context 'when :report_jemalloc_stats ops FF is enabled' do
      it { is_expected.to be true }
    end

    context 'when :report_jemalloc_stats ops FF is disabled' do
      before do
        stub_feature_flags(report_jemalloc_stats: false)
      end

      it { is_expected.to be false }
    end
  end
end

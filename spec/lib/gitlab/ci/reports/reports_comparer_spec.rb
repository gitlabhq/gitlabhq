# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::ReportsComparer do
  let(:comparer) { described_class.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::CodequalityReports.new }

  describe '#initialize' do
    context 'sets getter for the report comparer' do
      it 'return base report' do
        expect(comparer.base_report).to be_an_instance_of(Gitlab::Ci::Reports::CodequalityReports)
      end

      it 'return head report' do
        expect(comparer.head_report).to be_an_instance_of(Gitlab::Ci::Reports::CodequalityReports)
      end
    end
  end

  describe '#status' do
    subject(:status) { comparer.status }

    it 'returns not implemented error' do
      expect { status }.to raise_error(NotImplementedError)
    end

    context 'when success? is true' do
      before do
        allow(comparer).to receive(:success?).and_return(true)
      end

      it 'returns status success' do
        expect(status).to eq('success')
      end
    end

    context 'when success? is false' do
      before do
        allow(comparer).to receive(:success?).and_return(false)
      end

      it 'returns status failed' do
        expect(status).to eq('failed')
      end
    end

    context 'when base_report is nil' do
      let(:base_report) { nil }

      it 'returns status not_found' do
        expect(status).to eq('not_found')
      end
    end

    context 'when head_report is nil' do
      let(:head_report) { nil }

      it 'returns status not_found' do
        expect(status).to eq('not_found')
      end
    end
  end

  describe '#success?' do
    subject(:success?) { comparer.success? }

    it 'returns not implemented error' do
      expect { success? }.to raise_error(NotImplementedError)
    end
  end

  describe '#existing_errors' do
    subject(:existing_errors) { comparer.existing_errors }

    it 'returns not implemented error' do
      expect { existing_errors }.to raise_error(NotImplementedError)
    end
  end

  describe '#resolved_errors' do
    subject(:resolved_errors) { comparer.resolved_errors }

    it 'returns not implemented error' do
      expect { resolved_errors }.to raise_error(NotImplementedError)
    end
  end

  describe '#errors_count' do
    subject(:errors_count) { comparer.errors_count }

    it 'returns not implemented error' do
      expect { errors_count }.to raise_error(NotImplementedError)
    end
  end

  describe '#resolved_count' do
    subject(:resolved_count) { comparer.resolved_count }

    it 'returns not implemented error' do
      expect { resolved_count }.to raise_error(NotImplementedError)
    end
  end

  describe '#total_count' do
    subject(:total_count) { comparer.total_count }

    it 'returns not implemented error' do
      expect { total_count }.to raise_error(NotImplementedError)
    end
  end

  describe '#not_found?' do
    subject(:not_found) { comparer.not_found? }

    context 'when base report is nil' do
      let(:base_report) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when base report exists' do
      before do
        allow(comparer).to receive(:success?).and_return(true)
      end

      it { is_expected.to be_falsey }
    end
  end
end

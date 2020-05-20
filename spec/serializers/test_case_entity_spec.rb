# frozen_string_literal: true

require 'spec_helper'

describe TestCaseEntity do
  include TestReportsHelper

  let(:entity) { described_class.new(test_case) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when test case is success' do
      let(:test_case) { create_test_case_rspec_success }

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('success')
        expect(subject[:name]).to eq('Test#sum when a is 1 and b is 3 returns summary')
        expect(subject[:classname]).to eq('spec.test_spec')
        expect(subject[:execution_time]).to eq(1.11)
      end
    end

    context 'when test case is failed' do
      let(:test_case) { create_test_case_rspec_failed }

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('failed')
        expect(subject[:name]).to eq('Test#sum when a is 1 and b is 3 returns summary')
        expect(subject[:classname]).to eq('spec.test_spec')
        expect(subject[:execution_time]).to eq(2.22)
      end
    end

    context 'when feature is enabled' do
      before do
        stub_feature_flags(junit_pipeline_screenshots_view: true)
      end

      context 'when attachment is present' do
        let(:test_case) { build(:test_case, :failed_with_attachment) }

        it 'returns the attachment_url' do
          expect(subject).to include(:attachment_url)
        end
      end

      context 'when attachment is not present' do
        let(:test_case) { build(:test_case) }

        it 'returns a nil attachment_url' do
          expect(subject[:attachment_url]).to be_nil
        end
      end
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(junit_pipeline_screenshots_view: false)
      end

      context 'when attachment is present' do
        let(:test_case) { build(:test_case, :failed_with_attachment) }

        it 'returns no attachment_url' do
          expect(subject).not_to include(:attachment_url)
        end
      end

      context 'when attachment is not present' do
        let(:test_case) { build(:test_case) }

        it 'returns no attachment_url' do
          expect(subject).not_to include(:attachment_url)
        end
      end
    end
  end
end

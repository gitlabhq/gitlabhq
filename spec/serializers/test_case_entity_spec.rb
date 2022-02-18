# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestCaseEntity do
  include TestReportsHelper

  let_it_be(:job) { create(:ci_build) }

  let(:entity) { described_class.new(test_case) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when test case is success' do
      let(:test_case) { create_test_case_rspec_success }

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('success')
        expect(subject[:name]).to eq('Test#sum when a is 1 and b is 3 returns summary')
        expect(subject[:classname]).to eq('spec.test_spec')
        expect(subject[:file]).to eq('./spec/test_spec.rb')
        expect(subject[:execution_time]).to eq(1.11)
      end
    end

    context 'when test case is failed' do
      let(:test_case) { create_test_case_rspec_failed }

      before do
        test_case.set_recent_failures(3, 'master')
      end

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('failed')
        expect(subject[:name]).to eq('Test#sum when a is 1 and b is 3 returns summary')
        expect(subject[:classname]).to eq('spec.test_spec')
        expect(subject[:file]).to eq('./spec/test_spec.rb')
        expect(subject[:execution_time]).to eq(2.22)
        expect(subject[:recent_failures]).to eq({ count: 3, base_branch: 'master' })
      end
    end

    context 'when no test name is entered' do
      let(:test_case) { build(:report_test_case, name: "") }

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('success')
        expect(subject[:name]).to eq('(No name)')
        expect(subject[:classname]).to eq('trace')
        expect(subject[:file]).to eq('spec/trace_spec.rb')
        expect(subject[:execution_time]).to eq(1.23)
      end
    end

    context 'when attachment is present' do
      let(:test_case) { build(:report_test_case, :failed_with_attachment, job: job) }

      it 'returns the attachment_url' do
        expect(subject).to include(:attachment_url)
      end
    end

    context 'when attachment is not present' do
      let(:test_case) { build(:report_test_case, job: job) }

      it 'returns a nil attachment_url' do
        expect(subject[:attachment_url]).to be_nil
      end
    end
  end
end

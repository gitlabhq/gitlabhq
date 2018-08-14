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
        expect(subject[:execution_time]).to eq(1.11)
      end
    end

    context 'when test case is failed' do
      let(:test_case) { create_test_case_rspec_failed }

      it 'contains correct test case details' do
        expect(subject[:status]).to eq('failed')
        expect(subject[:name]).to eq('Test#sum when a is 2 and b is 2 returns summary')
        expect(subject[:execution_time]).to eq(2.22)
      end
    end
  end
end

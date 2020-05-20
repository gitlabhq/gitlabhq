# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::TestCase do
  describe '#initialize' do
    let(:test_case) { described_class.new(params)}

    context 'when both classname and name are given' do
      context 'when test case is passed' do
        let(:job) { build(:ci_build) }
        let(:params) { attributes_for(:test_case).merge!(job: job) }

        it 'initializes an instance' do
          expect { test_case }.not_to raise_error

          expect(test_case.name).to eq('test-1')
          expect(test_case.classname).to eq('trace')
          expect(test_case.file).to eq('spec/trace_spec.rb')
          expect(test_case.execution_time).to eq(1.23)
          expect(test_case.status).to eq(described_class::STATUS_SUCCESS)
          expect(test_case.system_output).to be_nil
          expect(test_case.job).to be_present
        end
      end

      context 'when test case is failed' do
        let(:job) { build(:ci_build) }
        let(:params) { attributes_for(:test_case, :failed).merge!(job: job) }

        it 'initializes an instance' do
          expect { test_case }.not_to raise_error

          expect(test_case.name).to eq('test-1')
          expect(test_case.classname).to eq('trace')
          expect(test_case.file).to eq('spec/trace_spec.rb')
          expect(test_case.execution_time).to eq(1.23)
          expect(test_case.status).to eq(described_class::STATUS_FAILED)
          expect(test_case.system_output)
            .to eq('Failure/Error: is_expected.to eq(300) expected: 300 got: -100')
        end
      end
    end

    shared_examples 'param is missing' do |param|
      let(:job) { build(:ci_build) }
      let(:params) { attributes_for(:test_case).merge!(job: job) }

      it 'raises an error' do
        params.delete(param)

        expect { test_case }.to raise_error(KeyError)
      end
    end

    context 'when classname is missing' do
      it_behaves_like 'param is missing', :classname
    end

    context 'when name is missing' do
      it_behaves_like 'param is missing', :name
    end

    context 'when attachment is present' do
      let(:attachment_test_case) { build(:test_case, :failed_with_attachment) }

      it "initializes the attachment if present" do
        expect(attachment_test_case.attachment).to eq("some/path.png")
      end

      it '#has_attachment?' do
        expect(attachment_test_case.has_attachment?).to be_truthy
      end

      it '#attachment_url' do
        expect(attachment_test_case.attachment_url).to match(/file\/some\/path.png/)
      end
    end

    context 'when attachment is missing' do
      let(:test_case) { build(:test_case) }

      it '#has_attachment?' do
        expect(test_case.has_attachment?).to be_falsy
      end

      it '#attachment_url' do
        expect(test_case.attachment_url).to be_nil
      end
    end
  end
end

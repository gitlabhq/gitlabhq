# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestCase, :aggregate_failures do
  describe '#initialize' do
    let(:test_case) { described_class.new(params) }

    context 'when required params are given' do
      let(:job) { build(:ci_build) }
      let(:params) { attributes_for(:report_test_case).merge!(job: job) }

      it 'initializes an instance', :aggregate_failures do
        expect { test_case }.not_to raise_error

        expect(test_case).to have_attributes(
          suite_name: params[:suite_name],
          name: params[:name],
          classname: params[:classname],
          file: params[:file],
          execution_time: params[:execution_time],
          status: params[:status],
          system_output: params[:system_output],
          job: params[:job]
        )

        key = "#{test_case.suite_name}_#{test_case.classname}_#{test_case.name}"
        expect(test_case.key).to eq(Digest::SHA256.hexdigest(key))
      end
    end

    shared_examples 'param is missing' do |param|
      let(:job) { build(:ci_build) }
      let(:params) { attributes_for(:report_test_case).merge!(job: job) }

      it 'raises an error' do
        params.delete(param)

        expect { test_case }.to raise_error(KeyError)
      end
    end

    context 'when suite_name is missing' do
      it_behaves_like 'param is missing', :suite_name
    end

    context 'when classname is missing' do
      it_behaves_like 'param is missing', :classname
    end

    context 'when name is missing' do
      it_behaves_like 'param is missing', :name
    end

    context 'when attachment is present' do
      let_it_be(:job) { create(:ci_build) }

      let(:attachment_test_case) { build(:report_test_case, :failed_with_attachment, job: job) }

      it "initializes the attachment if present" do
        expect(attachment_test_case.attachment).to eq("some/path.png")
      end

      it '#has_attachment?' do
        expect(attachment_test_case.has_attachment?).to be_truthy
      end

      it '#attachment_url' do
        expect(attachment_test_case.attachment_url).to match(%r{file/some/path.png})
      end
    end

    context 'when attachment is missing' do
      let(:test_case) { build(:report_test_case) }

      it '#has_attachment?' do
        expect(test_case.has_attachment?).to be_falsy
      end

      it '#attachment_url' do
        expect(test_case.attachment_url).to be_nil
      end
    end
  end

  describe '#set_recent_failures' do
    it 'sets the recent_failures information' do
      test_case = build(:report_test_case)

      test_case.set_recent_failures(1, 'master')

      expect(test_case.recent_failures).to eq(
        count: 1,
        base_branch: 'master'
      )
    end
  end
end

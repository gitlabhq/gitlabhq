require 'spec_helper'

describe Gitlab::Ci::Status::Factory do
  let(:user) { create(:user) }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(resource, user) }

  context 'when object has a core status' do
    HasStatus::AVAILABLE_STATUSES.each do |core_status|
      context "when core status is #{core_status}" do
        let(:resource) { double('resource', status: core_status) }

        it "fabricates a core status #{core_status}" do
          expect(status).to be_a(
            Gitlab::Ci::Status.const_get(core_status.capitalize))
        end
      end
    end
  end

  context 'when resource supports multiple extended statuses' do
    let(:resource) { double('resource', status: :success) }

    let(:first_extended_status) do
      Class.new(SimpleDelegator) do
        def first_method
          'first return value'
        end

        def second_method
          'second return value'
        end

        def self.matches?(*)
          true
        end
      end
    end

    let(:second_extended_status) do
      Class.new(SimpleDelegator) do
        def first_method
          'decorated return value'
        end

        def third_method
          'third return value'
        end

        def self.matches?(*)
          true
        end
      end
    end

    shared_examples 'compound decorator factory' do
      it 'fabricates compound decorator' do
        expect(status.first_method).to eq 'decorated return value'
        expect(status.second_method).to eq 'second return value'
        expect(status.third_method).to eq 'third return value'
      end

      it 'delegates to core status' do
        expect(status.text).to eq 'passed'
      end

      it 'latest matches status becomes a status name' do
        expect(status.class).to eq second_extended_status
      end
    end

    context 'when exclusive statuses are matches' do
      before do
        allow(described_class).to receive(:extended_statuses)
          .and_return([[first_extended_status, second_extended_status]])
      end

      it 'fabricates compound decorator' do
        expect(status.first_method).to eq 'first return value'
        expect(status.second_method).to eq 'second return value'
        expect(status).not_to respond_to(:third_method)
      end

      it 'delegates to core status' do
        expect(status.text).to eq 'passed'
      end
    end

    context 'when exclusive statuses are not matched' do
      before do
        allow(described_class).to receive(:extended_statuses)
          .and_return([[first_extended_status], [second_extended_status]])
      end

      it_behaves_like 'compound decorator factory'
    end

    context 'when using simplified status grouping' do
      before do
        allow(described_class).to receive(:extended_statuses)
          .and_return([first_extended_status, second_extended_status])
      end

      it_behaves_like 'compound decorator factory'
    end
  end
end

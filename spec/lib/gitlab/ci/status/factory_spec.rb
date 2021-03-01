# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Factory do
  let(:user) { create(:user) }
  let(:fabricated_status) { factory.fabricate! }
  let(:factory) { described_class.new(resource, user) }

  context 'when object has a core status' do
    Ci::HasStatus::AVAILABLE_STATUSES.each do |simple_status|
      context "when simple core status is #{simple_status}" do
        let(:resource) { double('resource', status: simple_status) }

        let(:expected_status) do
          Gitlab::Ci::Status.const_get(simple_status.to_s.camelize, false)
        end

        it "fabricates a core status #{simple_status}" do
          expect(fabricated_status).to be_a expected_status
        end

        it "matches a valid core status for #{simple_status}" do
          expect(factory.core_status).to be_a expected_status
        end

        it "does not match any extended statuses for #{simple_status}" do
          expect(factory.extended_statuses).to be_empty
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
        expect(fabricated_status.first_method).to eq 'decorated return value'
        expect(fabricated_status.second_method).to eq 'second return value'
        expect(fabricated_status.third_method).to eq 'third return value'
      end

      it 'delegates to core status' do
        expect(fabricated_status.text).to eq 'passed'
      end

      it 'latest matches status becomes a status name' do
        expect(fabricated_status.class).to eq second_extended_status
      end

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses)
          .to eq [first_extended_status, second_extended_status]
      end
    end

    context 'when exclusive statuses are matches' do
      before do
        allow(described_class).to receive(:extended_statuses)
          .and_return([[first_extended_status, second_extended_status]])
      end

      it 'does not fabricate compound decorator' do
        expect(fabricated_status.first_method).to eq 'first return value'
        expect(fabricated_status.second_method).to eq 'second return value'
        expect(fabricated_status).not_to respond_to(:third_method)
      end

      it 'delegates to core status' do
        expect(fabricated_status.text).to eq 'passed'
      end

      it 'matches correct core status' do
        expect(factory.core_status).to be_a Gitlab::Ci::Status::Success
      end

      it 'matches correct extended statuses' do
        expect(factory.extended_statuses).to eq [first_extended_status]
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

  context 'behaviour of FactoryBot traits that create associations' do
    context 'creating a namespace with an associated aggregation_schedule record' do
      it 'creates only one Namespace record and one Namespace::AggregationSchedule record' do
        expect { create(:namespace, :with_aggregation_schedule) }
          .to change { Namespace.count }.by(1)
          .and change { Namespace::AggregationSchedule.count }.by(1)
      end
    end
  end
end

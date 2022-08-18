# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::TerraformReports do
  it 'initializes plans with and empty hash' do
    expect(subject.plans).to eq({})
  end

  describe '#add_plan' do
    context 'when providing two unique plans' do
      it 'returns two plans' do
        subject.add_plan('123', { 'create' => 1, 'update' => 2, 'delete' => 3 })
        subject.add_plan('456', { 'create' => 4, 'update' => 5, 'delete' => 6 })

        expect(subject.plans).to eq({
          '123' => { 'create' => 1, 'update' => 2, 'delete' => 3 },
          '456' => { 'create' => 4, 'update' => 5, 'delete' => 6 }
        })
      end
    end

    context 'when providing the same plan twice' do
      it 'returns the last added plan' do
        subject.add_plan('123', { 'create' => 0, 'update' => 0, 'delete' => 0 })
        subject.add_plan('123', { 'create' => 1, 'update' => 2, 'delete' => 3 })

        expect(subject.plans).to eq({
          '123' => { 'create' => 1, 'update' => 2, 'delete' => 3 }
        })
      end
    end
  end
end

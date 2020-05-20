# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::TerraformReports do
  it 'initializes plans with and empty hash' do
    expect(subject.plans).to eq({})
  end

  describe '#add_plan' do
    context 'when providing two unique plans' do
      it 'returns two plans' do
        subject.add_plan('a/tfplan.json', { 'create' => 0, 'update' => 1, 'delete' => 0 })
        subject.add_plan('b/tfplan.json', { 'create' => 0, 'update' => 1, 'delete' => 0 })

        expect(subject.plans).to eq({
          'a/tfplan.json' => { 'create' => 0, 'update' => 1, 'delete' => 0 },
          'b/tfplan.json' => { 'create' => 0, 'update' => 1, 'delete' => 0 }
        })
      end
    end

    context 'when providing the same plan twice' do
      it 'returns the last added plan' do
        subject.add_plan('tfplan.json', { 'create' => 0, 'update' => 0, 'delete' => 0 })
        subject.add_plan('tfplan.json', { 'create' => 0, 'update' => 1, 'delete' => 0 })

        expect(subject.plans).to eq({
          'tfplan.json' => { 'create' => 0, 'update' => 1, 'delete' => 0 }
        })
      end
    end
  end
end

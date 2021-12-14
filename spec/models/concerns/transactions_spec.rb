# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transactions do
  let(:model) { build(:project) }

  it 'is not in a transaction' do
    expect(model.class).not_to be_inside_transaction
  end

  it 'is in a transaction', :aggregate_failures do
    Project.transaction do
      expect(model.class).to be_inside_transaction
    end

    ApplicationRecord.transaction do
      expect(model.class).to be_inside_transaction
    end
  end
end

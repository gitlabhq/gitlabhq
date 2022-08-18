# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes do
  describe '.create_pending_indexes!' do
    subject { described_class.create_pending_indexes! }

    before do
      create_list(:postgres_async_index, 4)
    end

    it 'takes 2 pending indexes and creates those' do
      Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.to_create.order(:id).limit(2).each do |index|
        creator = double('index creator')
        expect(Gitlab::Database::AsyncIndexes::IndexCreator).to receive(:new).with(index).and_return(creator)
        expect(creator).to receive(:perform)
      end

      subject
    end
  end

  describe '.drop_pending_indexes!' do
    subject { described_class.drop_pending_indexes! }

    before do
      create_list(:postgres_async_index, 4, :with_drop)
    end

    it 'takes 2 pending indexes and destroys those' do
      Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.to_drop.order(:id).limit(2).each do |index|
        destructor = double('index destructor')
        expect(Gitlab::Database::AsyncIndexes::IndexDestructor).to receive(:new).with(index).and_return(destructor)
        expect(destructor).to receive(:perform)
      end

      subject
    end
  end
end

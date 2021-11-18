# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::DatabaseHelpers do
  let(:database_helper) do
    Class.new do
      include Gitlab::Import::DatabaseHelpers
    end
  end

  subject { database_helper.new }

  describe '.insert_and_return_id' do
    let(:attributes) { { iid: 1, title: 'foo' } }
    let(:project) { create(:project) }

    it 'returns the ID returned by the query' do
      expect(ApplicationRecord)
        .to receive(:legacy_bulk_insert)
        .with(Issue.table_name, [attributes], return_ids: true)
        .and_return([10])

      id = subject.insert_and_return_id(attributes, project.issues)

      expect(id).to eq(10)
    end
  end
end

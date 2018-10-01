# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Import::DatabaseHelpers do
  let(:database_helper) do
    Class.new do
      include Gitlab::Import::DatabaseHelpers
    end
  end

  subject { database_helper.new }

  describe '.insert_and_return_id' do
    let(:attributes) { { iid: 1, title: 'foo' } }
    let(:project) { create(:project) }

    context 'on PostgreSQL' do
      it 'returns the ID returned by the query' do
        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .with(Issue.table_name, [attributes], return_ids: true)
          .and_return([10])

        id = subject.insert_and_return_id(attributes, project.issues)

        expect(id).to eq(10)
      end
    end

    context 'on MySQL' do
      it 'uses a separate query to retrieve the ID' do
        issue = create(:issue, project: project, iid: attributes[:iid])

        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .with(Issue.table_name, [attributes], return_ids: true)
          .and_return([])

        id = subject.insert_and_return_id(attributes, project.issues)

        expect(id).to eq(issue.id)
      end
    end
  end
end

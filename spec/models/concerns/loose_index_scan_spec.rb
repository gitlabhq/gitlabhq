# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseIndexScan, type: :model do
  let(:issue_model) do
    Class.new(ApplicationRecord) do
      include LooseIndexScan

      self.table_name = 'issues'
    end
  end

  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:user_3) { create(:user) }

  let_it_be(:issue_1) { create(:issue, author: user_2) }
  let_it_be(:issue_2) { create(:issue, author: user_1) }
  let_it_be(:issue_3) { create(:issue, author: user_1) }
  let_it_be(:issue_4) { create(:issue, author: user_2) }
  let_it_be(:issue_5) { create(:issue, author: user_3) }

  context 'loading distinct author_ids' do
    subject(:author_ids) do
      issue_model
        .loose_index_scan(column: issue_model.arel_table[:author_id].as("example_alias"), order: order)
        .pluck(:example_alias)
    end

    shared_examples 'assert distinct values example' do
      it 'loads the distinct values in the correct order' do
        expect(author_ids).to eq(expected_order)
      end
    end

    context 'when using ascending order' do
      let(:order) { :asc }
      let(:expected_order) { [user_1.id, user_2.id, user_3.id] }

      it_behaves_like 'assert distinct values example'

      context 'when null values are present' do
        before do
          issue_1.author_id = nil
          issue_1.save!(validate: false)
        end

        it_behaves_like 'assert distinct values example'
      end

      context 'when using descending order' do
        let(:order) { :desc }
        let(:expected_order) { [user_3.id, user_2.id, user_1.id] }

        it_behaves_like 'assert distinct values example'
      end
    end
  end

  context 'using Arel column objects' do
    subject(:author_ids) do
      issue_model.loose_index_scan(column: issue_model.arel_table[:author_id], order: order).pluck(:author_id)
    end

    context 'when using ascending order' do
      let(:order) { :asc }
      let(:expected_order) { [user_1.id, user_2.id, user_3.id] }

      it 'loads the distinct values in the correct order' do
        expect(author_ids).to eq(expected_order)
      end
    end

    context 'when using descending order' do
      let(:order) { :desc }
      let(:expected_order) { [user_3.id, user_2.id, user_1.id] }

      it 'loads the distinct values in the correct order' do
        expect(author_ids).to eq(expected_order)
      end
    end
  end

  context 'loading distinct values from a different column' do
    # Create completely separate test data for this context
    let_it_be(:project_context_user_1) { create(:user) }
    let_it_be(:project_context_user_2) { create(:user) }
    let_it_be(:project_context_user_3) { create(:user) }

    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    # Create issues with projects already assigned
    let_it_be(:project_issue_1) { create(:issue, project: project_1, author: project_context_user_2) }
    let_it_be(:project_issue_2) { create(:issue, project: project_2, author: project_context_user_1) }
    let_it_be(:project_issue_3) { create(:issue, project: project_2, author: project_context_user_1) }
    let_it_be(:project_issue_4) { create(:issue, project: project_1, author: project_context_user_2) }
    let_it_be(:project_issue_5) { create(:issue, project: project_3, author: project_context_user_3) }

    # Only use the issues created specifically for this test
    let(:project_test_scope) do
      issue_ids = [
        project_issue_1.id,
        project_issue_2.id,
        project_issue_3.id,
        project_issue_4.id,
        project_issue_5.id
      ]
      issue_model.where(id: issue_ids)
    end

    subject(:project_ids) { project_test_scope.loose_index_scan(column: :project_id, order: order).pluck(:project_id) }

    context 'when using ascending order' do
      let(:order) { :asc }
      let(:expected_order) { [project_1.id, project_2.id, project_3.id] }

      it 'loads the distinct values in the correct order' do
        expect(project_ids).to eq(expected_order)
      end
    end

    context 'when using descending order' do
      let(:order) { :desc }
      let(:expected_order) { [project_3.id, project_2.id, project_1.id] }

      it 'loads the distinct values in the correct order' do
        expect(project_ids).to eq(expected_order)
      end
    end
  end
end

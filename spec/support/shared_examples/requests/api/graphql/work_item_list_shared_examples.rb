# frozen_string_literal: true

RSpec.shared_examples 'graphql work item list request spec' do
  let(:work_item_ids) { graphql_dig_at(work_item_data, :id) }

  it_behaves_like 'a working graphql query' do
    before do
      post_query
    end
  end

  describe 'filters' do
    before do
      post_query
    end

    context 'when filtering by author username' do
      let(:author) { create(:author) }
      let(:authored_work_item) { create(:work_item, author: author, **container_build_params) }

      let(:item_filter_params) { { author_username: authored_work_item.author.username } }

      it 'returns correct results' do
        expect(work_item_ids).to contain_exactly(authored_work_item.to_global_id.to_s)
      end
    end

    context 'when filtering by state' do
      let_it_be(:opened_work_item) { create(:work_item, :opened, **container_build_params) }
      let_it_be(:closed_work_item) { create(:work_item, :closed, **container_build_params) }

      context 'when filtering by state opened' do
        let(:item_filter_params) { { state: :opened } }

        it 'filters by state' do
          expect(work_item_ids).to include(opened_work_item.to_global_id.to_s)
          expect(work_item_ids).not_to include(closed_work_item.to_global_id.to_s)
        end
      end

      context 'when filtering by state closed' do
        let(:item_filter_params) { { state: :closed } }

        it 'filters by state' do
          expect(work_item_ids).not_to include(opened_work_item.to_global_id.to_s)
          expect(work_item_ids).to include(closed_work_item.to_global_id.to_s)
        end
      end

      context 'when filtering by state locked' do
        let(:item_filter_params) { { state: :locked } }

        it 'return an error message' do
          expect_graphql_errors_to_include(Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE)
        end
      end
    end

    context 'when filtering by type' do
      let_it_be(:issue_work_item) { create(:work_item, :issue, **container_build_params) }
      let_it_be(:task_work_item) { create(:work_item, :task, **container_build_params) }

      context 'when filtering by issue type' do
        let(:item_filter_params) { { types: [:ISSUE] } }

        it 'filters by type' do
          expect(work_item_ids).to include(issue_work_item.to_global_id.to_s)
          expect(work_item_ids).not_to include(task_work_item.to_global_id.to_s)
        end
      end

      context 'when filtering by task type' do
        let(:item_filter_params) { { types: [:TASK] } }

        it 'filters by type' do
          expect(work_item_ids).not_to include(issue_work_item.to_global_id.to_s)
          expect(work_item_ids).to include(task_work_item.to_global_id.to_s)
        end
      end
    end

    context 'when filtering by iid' do
      let_it_be(:work_item_by_iid) { create(:work_item, **container_build_params) }

      context 'when using the iid filter' do
        let(:item_filter_params) { { iid: work_item_by_iid.iid.to_s } }

        it 'returns only items by the given iid' do
          expect(work_item_ids).to contain_exactly(work_item_by_iid.to_global_id.to_s)
        end
      end

      context 'when using the iids filter' do
        let(:item_filter_params) { { iids: [work_item_by_iid.iid.to_s] } }

        it 'returns only items by the given iid' do
          expect(work_item_ids).to contain_exactly(work_item_by_iid.to_global_id.to_s)
        end
      end
    end
  end

  def work_item_data
    graphql_data.dig(*work_item_node_path)
  end
end

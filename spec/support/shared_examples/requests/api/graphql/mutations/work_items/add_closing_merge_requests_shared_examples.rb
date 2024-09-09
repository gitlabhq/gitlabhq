# frozen_string_literal: true

RSpec.shared_examples 'a mutation that does not add closing merge request' do
  let(:error_array) { graphql_errors }
  let(:expected_errors) do
    hash_including(
      'message' => "The resource that you are attempting to access does not exist or you don't have " \
        'permission to perform this action'
    )
  end

  it 'does not add the closing merge request' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
    end.to not_change { MergeRequestsClosingIssues.count }

    expect(error_array).to contain_exactly(
      expected_errors
    )
  end
end

RSpec.shared_examples 'a mutation that adds closing merge request' do
  context 'when the user cannot update the work item' do
    let(:current_user) { unauthorized_user }

    it_behaves_like 'a mutation that does not add closing merge request'
  end

  context 'when the user can update the work item' do
    it 'adds the closing merge request' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { MergeRequestsClosingIssues.count }.by(1)

      expect(mutation_response).to include(
        'closingMergeRequest' => hash_including(
          'mergeRequest' => { 'id' => merge_request.to_gid.to_s },
          'fromMrDescription' => false
        ),
        'workItem' => hash_including(
          'id' => work_item.to_global_id.to_s,
          'widgets' => array_including(
            hash_including(
              'type' => 'DEVELOPMENT',
              'closingMergeRequests' => {
                'nodes' => containing_exactly(
                  hash_including(
                    'mergeRequest' => { 'id' => merge_request.to_global_id.to_s },
                    'fromMrDescription' => false
                  )
                )
              }
            )
          )
        )
      )
    end

    context 'when the target work item does not have a development widget' do
      before do
        work_item.work_item_type.widget_definitions.where(name: 'Development').update_all(disabled: true)
      end

      it_behaves_like 'a mutation that does not add closing merge request' do
        let(:error_array) { mutation_response['errors'] }
        let(:expected_errors) { _('Development widget is not enabled for this work item type') }
      end
    end

    context 'when the user does not have access to a the merge request' do
      let(:namespace_path) { private_merge_request.project.full_path }
      let(:mr_reference) { private_merge_request.to_reference }

      it_behaves_like 'a mutation that does not add closing merge request'
    end

    context 'when context path is not provided' do
      let(:namespace_path) { nil }

      context 'when the reference is a full URL' do
        let(:mr_reference) { Gitlab::UrlBuilder.build(merge_request) }

        it 'adds the closing merge request' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { MergeRequestsClosingIssues.count }.by(1)
        end
      end
    end

    context 'when the context path belongs to a group' do
      let(:namespace_path) { group.full_path }

      it_behaves_like 'a mutation that does not add closing merge request'

      context 'when the reference is a full URL' do
        let(:mr_reference) { Gitlab::UrlBuilder.build(merge_request) }

        it 'adds the closing merge request' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { MergeRequestsClosingIssues.count }.by(1)
        end
      end
    end
  end
end

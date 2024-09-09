# frozen_string_literal: true

RSpec.shared_examples 'a service that works for full references and URLs' do
  context 'when the merge request reference is a full reference' do
    let(:mr_reference) { merge_request.to_reference(full: true) }

    it 'adds the closing merge requests' do
      expect do
        create_result
      end.to change { MergeRequestsClosingIssues.count }.by(1)

      expect(create_result).to be_success
    end
  end

  context 'when the merge request reference is a full URL' do
    let(:mr_reference) { Gitlab::UrlBuilder.build(merge_request) }

    it 'adds the closing merge requests' do
      expect do
        create_result
      end.to change { MergeRequestsClosingIssues.count }.by(1)

      expect(create_result).to be_success
    end
  end
end

RSpec.shared_examples 'a service that adds closing merge requests' do
  context 'when the user cannot update the work item' do
    let(:current_user) { unauthorized_user }

    it 'raises a resource not available error' do
      expect { create_result }.to raise_error(described_class::ResourceNotAvailable)
    end
  end

  context 'when the user can update the work item' do
    it 'adds the closing merge requests' do
      expect do
        create_result
      end.to change { MergeRequestsClosingIssues.count }.by(1)

      expect(create_result).to be_success
    end

    it 'sets from_mr_description to false' do
      expect(create_result.payload[:merge_request_closing_issue].from_mr_description).to be_falsey
    end

    it_behaves_like 'a service that works for full references and URLs'

    context 'when the merge request was already associated with the work item' do
      before do
        create(:merge_requests_closing_issues, merge_request: merge_request, issue_id: work_item.id)
      end

      it 'does not add the closing merge requests' do
        expect do
          create_result
        end.to not_change { MergeRequestsClosingIssues.count }
      end

      it 'returns an error message' do
        expect(create_result.errors).to contain_exactly('Merge request has already been taken')
      end

      it { is_expected.to be_error }
    end

    context 'when the target work item does not have a development widget' do
      before do
        work_item.work_item_type.widget_definitions.where(name: 'Development').update_all(disabled: true)
      end

      it 'does not add the closing merge requests' do
        expect do
          create_result
        end.to not_change { MergeRequestsClosingIssues.count }
      end

      it 'returns an error message' do
        expect(create_result.errors).to contain_exactly(
          _('Development widget is not enabled for this work item type')
        )
      end

      it { is_expected.to be_error }
    end

    context 'when the user does not have access to a the merge request' do
      let(:namespace_path) { private_merge_request.project.full_path }
      let(:mr_reference) { private_merge_request.to_reference }

      it 'raises a resource not available error' do
        expect { create_result }.to raise_error(described_class::ResourceNotAvailable)
      end
    end

    context 'when the context path belongs to a group' do
      let(:namespace_path) { group.full_path }

      it 'raises a resource not available error' do
        expect { create_result }.to raise_error(described_class::ResourceNotAvailable)
      end

      it_behaves_like 'a service that works for full references and URLs'
    end

    context 'when context path is nil' do
      let(:namespace_path) { nil }

      it_behaves_like 'a service that works for full references and URLs'
    end
  end
end

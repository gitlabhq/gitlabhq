# frozen_string_literal: true

RSpec.shared_examples 'issues link quick action' do |command|
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_reload(:other_issue) { create(:issue, project: project) }
  let_it_be_with_reload(:second_issue) { create(:issue, project: project) }
  let_it_be_with_reload(:third_issue) { create(:issue, project: project) }
  let_it_be_with_reload(:work_item_issue) { create(:work_item, project: project) }
  let_it_be(:work_item_issue_link) { Issue.find(work_item_issue.id) }

  let(:link_type) { command == :relate ? 'relates_to' : 'blocks' }
  let(:links_query) do
    if command == :blocked_by
      IssueLink.where(target: issue, link_type: link_type).map(&:source)
    else
      IssueLink.where(source: issue, link_type: link_type).map(&:target)
    end
  end

  shared_examples 'link command' do
    it 'links issues' do
      service.execute(content, issue)

      expect(links_query).to match_array(issues_linked)
    end
  end

  context 'when user is member of group' do
    before do
      group.add_developer(user)
    end

    context 'when linking a single issue' do
      let(:issues_linked) { [other_issue] }
      let(:content) { "/#{command} #{other_issue.to_reference}" }

      it_behaves_like 'link command'
    end

    context 'when linking multiple issues at once' do
      let(:issues_linked) { [second_issue, third_issue, work_item_issue_link] }
      let(:content) do
        "/#{command} #{second_issue.to_reference} #{third_issue.to_reference} #{work_item_issue.to_reference}"
      end

      it_behaves_like 'link command'
    end

    context 'when quick action target is unpersisted' do
      let(:issue) { build(:issue, project: project) }
      let(:issues_linked) { [other_issue] }
      let(:content) { "/#{command} #{other_issue.to_reference}" }

      it 'links the issues after the issue is persisted' do
        service.execute(content, issue)

        issue.save!

        expect(links_query).to match_array(issues_linked)
      end
    end

    context 'with empty link command' do
      let(:issues_linked) { [] }
      let(:content) { "/#{command}" }

      it_behaves_like 'link command'
    end

    context 'with already having linked issues' do
      let(:issues_linked) { [second_issue, third_issue] }
      let(:content) { "/#{command} #{third_issue.to_reference(project)}" }

      before do
        create_existing_link(command)
      end

      it_behaves_like 'link command'
    end

    context 'with cross project' do
      let_it_be_with_reload(:another_group) { create(:group, :public) }
      let_it_be_with_reload(:other_project) { create(:project, group: another_group) }

      before do
        another_group.add_developer(user)
        [other_issue, second_issue, third_issue].map { |i| i.update!(project: other_project) }
      end

      context 'when linking a cross project issue' do
        let(:issues_linked) { [other_issue] }
        let(:content) { "/#{command} #{other_issue.to_reference(project)}" }

        it_behaves_like 'link command'
      end

      context 'when linking multiple cross projects issues at once' do
        let(:issues_linked) { [second_issue, third_issue] }
        let(:content) { "/#{command} #{second_issue.to_reference(project)} #{third_issue.to_reference(project)}" }

        it_behaves_like 'link command'
      end

      context 'when linking a non-existing issue' do
        let(:issues_linked) { [] }
        let(:content) { "/#{command} imaginary##{non_existing_record_iid}" }

        it_behaves_like 'link command'
      end

      context 'when linking a private issue' do
        let_it_be(:private_issue) { create(:issue, project: create(:project, :private)) }
        let(:issues_linked) { [] }
        let(:content) { "/#{command} #{private_issue.to_reference(project)}" }

        it_behaves_like 'link command'
      end
    end
  end

  def create_existing_link(command)
    issues = [issue, second_issue]
    source, target = command == :blocked_by ? issues.reverse : issues

    create(:issue_link, source: source, target: target, link_type: link_type)
  end
end

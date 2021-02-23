# frozen_string_literal: true

RSpec.shared_context 'project issuable templates context' do
  let_it_be(:issuable_template_files) do
    {
      '.gitlab/issue_templates/issue-bar.md' => 'Issue Template Bar',
      '.gitlab/issue_templates/issue-foo.md' => 'Issue Template Foo',
      '.gitlab/issue_templates/issue-bad.txt' => 'Issue Template Bad',
      '.gitlab/issue_templates/issue-baz.xyz' => 'Issue Template Baz',

      '.gitlab/merge_request_templates/merge_request-bar.md' => 'Merge Request Template Bar',
      '.gitlab/merge_request_templates/merge_request-foo.md' => 'Merge Request Template Foo',
      '.gitlab/merge_request_templates/merge_request-bad.txt' => 'Merge Request Template Bad',
      '.gitlab/merge_request_templates/merge_request-baz.xyz' => 'Merge Request Template Baz'
    }
  end
end

RSpec.shared_examples 'project issuable templates' do
  context 'issuable templates' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns only md files as issue templates' do
      expect(helper.issuable_templates(project, 'issue')).to eq(expected_templates('issue'))
    end

    it 'returns only md files as merge_request templates' do
      expect(helper.issuable_templates(project, 'merge_request')).to eq(expected_templates('merge_request'))
    end
  end

  def expected_templates(issuable_type)
    expectation = {}

    expectation["Project Templates"] = templates(issuable_type, project)
    expectation["Group #{inherited_from.namespace.full_name}"] = templates(issuable_type, inherited_from) if inherited_from.present?

    expectation
  end

  def templates(issuable_type, inherited_from)
    [
      { id: "#{issuable_type}-bar", key: "#{issuable_type}-bar", name: "#{issuable_type}-bar", project_id: inherited_from&.id },
      { id: "#{issuable_type}-foo", key: "#{issuable_type}-foo", name: "#{issuable_type}-foo", project_id: inherited_from&.id }
    ]
  end
end

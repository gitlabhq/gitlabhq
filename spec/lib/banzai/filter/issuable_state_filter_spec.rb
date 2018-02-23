require 'spec_helper'

describe Banzai::Filter::IssuableStateFilter do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  let(:user) { create(:user) }
  let(:context) { { current_user: user, issuable_state_filter_enabled: true } }
  let(:closed_issue) { create_issue(:closed) }
  let(:project) { create(:project, :public) }
  let(:other_project) { create(:project, :public) }

  def create_link(text, data)
    link_to(text, '', class: 'gfm has-tooltip', data: data)
  end

  def create_issue(state)
    create(:issue, state, project: project)
  end

  def create_merge_request(state)
    create(:merge_request, state,
      source_project: project, target_project: project)
  end

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: user)

    expect(doc.css('a').last.text).to eq('Google')
  end

  it 'ignores non-issuable links' do
    link = create_link('text', project: project, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  it 'ignores issuable links with empty content' do
    link = create_link('', issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('')
  end

  it 'ignores issuable links with custom anchor' do
    link = create_link('something', issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('something')
  end

  it 'ignores issuable links to specific comments' do
    link = create_link("#{closed_issue.to_reference} (comment 1)", issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference} (comment 1)")
  end

  it 'ignores merge request links to diffs tab' do
    merge_request = create(:merge_request, :closed)
    link = create_link(
      "#{merge_request.to_reference} (diffs)",
      merge_request: merge_request.id,
      reference_type: 'merge_request'
    )
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (diffs)")
  end

  it 'handles cross project references' do
    link = create_link(closed_issue.to_reference(other_project), issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: other_project))

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference(other_project)} (closed)")
  end

  it 'skips cross project references if the user cannot read cross project' do
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
    link = create_link(closed_issue.to_reference(other_project), issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: other_project))

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference(other_project)}")
  end

  it 'does not append state when filter is not enabled' do
    link = create_link('text', issue: closed_issue.id, reference_type: 'issue')
    context = { current_user: user }
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  context 'when project is in pending delete' do
    before do
      project.update!(pending_delete: true)
    end

    it 'does not append issue state' do
      link = create_link('text', issue: closed_issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq('text')
    end
  end

  context 'for issue references' do
    it 'ignores open issue references' do
      issue = create_issue(:opened)
      link = create_link(issue.to_reference, issue: issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(issue.to_reference)
    end

    it 'appends state to closed issue references' do
      link = create_link(closed_issue.to_reference, issue: closed_issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference} (closed)")
    end
  end

  context 'for merge request references' do
    it 'ignores open merge request references' do
      merge_request = create_merge_request(:opened)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'ignores reopened merge request references' do
      merge_request = create_merge_request(:opened)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'ignores locked merge request references' do
      merge_request = create_merge_request(:locked)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'appends state to closed merge request references' do
      merge_request = create_merge_request(:closed)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (closed)")
    end

    it 'appends state to merged merge request references' do
      merge_request = create_merge_request(:merged)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (merged)")
    end
  end
end

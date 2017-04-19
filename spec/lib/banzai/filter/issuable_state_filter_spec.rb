require 'spec_helper'

describe Banzai::Filter::IssuableStateFilter, lib: true do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  let(:user) { create(:user) }
  let(:context) { { current_user: user, issuable_state_filter_enabled: true } }

  def create_link(text, data)
    link_to(text, '', class: 'gfm has-tooltip', data: data)
  end

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: user)

    expect(doc.css('a').last.text).to eq('Google')
  end

  it 'ignores non-issuable links' do
    project = create(:empty_project, :public)
    link = create_link('text', project: project, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  it 'ignores issuable links with empty content' do
    issue = create(:issue, :closed)
    link = create_link('', issue: issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('')
  end

  it 'ignores issuable links with custom anchor' do
    issue = create(:issue, :closed)
    link = create_link('something', issue: issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('something')
  end

  it 'ignores issuable links to specific comments' do
    issue = create(:issue, :closed)
    link = create_link("#{issue.to_reference} (comment 1)", issue: issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{issue.to_reference} (comment 1)")
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
    issue = create(:issue, :closed)
    project = create(:empty_project)
    link = create_link(issue.to_reference(project), issue: issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: project))

    expect(doc.css('a').last.text).to eq("#{issue.to_reference(project)} (closed)")
  end

  it 'does not append state when filter is not enabled' do
    issue = create(:issue, :closed)
    link = create_link('text', issue: issue.id, reference_type: 'issue')
    context = { current_user: user }
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  context 'for issue references' do
    it 'ignores open issue references' do
      issue = create(:issue)
      link = create_link(issue.to_reference, issue: issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(issue.to_reference)
    end

    it 'ignores reopened issue references' do
      issue = create(:issue, :reopened)
      link = create_link(issue.to_reference, issue: issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(issue.to_reference)
    end

    it 'appends state to closed issue references' do
      issue = create(:issue, :closed)
      link = create_link(issue.to_reference, issue: issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issue.to_reference} (closed)")
    end
  end

  context 'for merge request references' do
    it 'ignores open merge request references' do
      merge_request = create(:merge_request)
      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'ignores reopened merge request references' do
      merge_request = create(:merge_request, :reopened)
      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'ignores locked merge request references' do
      merge_request = create(:merge_request, :locked)
      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'appends state to closed merge request references' do
      merge_request = create(:merge_request, :closed)
      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (closed)")
    end

    it 'appends state to merged merge request references' do
      merge_request = create(:merge_request, :merged)
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

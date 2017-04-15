require 'spec_helper'

describe Banzai::Filter::IssuableStateFilter, lib: true do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  let(:user) { create(:user) }

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
    doc = filter(link, current_user: user)

    expect(doc.css('a').last.text).to eq('text')
  end

  it 'ignores issuable links with empty content' do
    issue = create(:issue, :closed)
    link = create_link('', issue: issue.id, reference_type: 'issue')
    doc = filter(link, current_user: user)

    expect(doc.css('a').last.text).to eq('')
  end

  it 'adds text with standard formatting' do
    issue = create(:issue, :closed)
    link = create_link(
      'something <strong>else</strong>'.html_safe,
      issue: issue.id,
      reference_type: 'issue'
    )
    doc = filter(link, current_user: user)

    expect(doc.css('a').last.inner_html).
      to eq('something <strong>else</strong> [closed]')
  end

  context 'for issue references' do
    it 'ignores open issue references' do
      issue = create(:issue)
      link = create_link('text', issue: issue.id, reference_type: 'issue')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text')
    end

    it 'ignores reopened issue references' do
      reopened_issue = create(:issue, :reopened)
      link = create_link('text', issue: reopened_issue.id, reference_type: 'issue')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text')
    end

    it 'appends [closed] to closed issue references' do
      closed_issue = create(:issue, :closed)
      link = create_link('text', issue: closed_issue.id, reference_type: 'issue')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text [closed]')
    end
  end

  context 'for merge request references' do
    it 'ignores open merge request references' do
      mr = create(:merge_request)
      link = create_link('text', merge_request: mr.id, reference_type: 'merge_request')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text')
    end

    it 'ignores reopened merge request references' do
      mr = create(:merge_request, :reopened)
      link = create_link('text', merge_request: mr.id, reference_type: 'merge_request')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text')
    end

    it 'ignores locked merge request references' do
      mr = create(:merge_request, :locked)
      link = create_link('text', merge_request: mr.id, reference_type: 'merge_request')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text')
    end

    it 'appends [closed] to closed merge request references' do
      mr = create(:merge_request, :closed)
      link = create_link('text', merge_request: mr.id, reference_type: 'merge_request')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text [closed]')
    end

    it 'appends [merged] to merged merge request references' do
      mr = create(:merge_request, :merged)
      link = create_link('text', merge_request: mr.id, reference_type: 'merge_request')
      doc = filter(link, current_user: user)

      expect(doc.css('a').last.text).to eq('text [merged]')
    end
  end
end

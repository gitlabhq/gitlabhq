# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::IssueReferenceFilter do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  def helper
    IssuesHelper
  end

  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:issue_path) { "/#{issue.project.namespace.path}/#{issue.project.path}/-/issues/#{issue.iid}" }
  let(:issue_url) { "http://#{Gitlab.config.gitlab.host}#{issue_path}" }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Issue #{issue.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  describe 'performance' do
    let(:another_issue) { create(:issue, project: project) }

    it 'does not have a N+1 query problem' do
      single_reference = "Issue #{issue.to_reference}"
      multiple_references = "Issues #{issue.to_reference} and #{another_issue.to_reference}"

      control_count = ActiveRecord::QueryRecorder.new { reference_filter(single_reference).to_html }.count

      expect { reference_filter(multiple_references).to_html }.not_to exceed_query_limit(control_count)
    end
  end

  context 'internal reference' do
    let(:reference) { "##{issue.iid}" }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("Fixed #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.text).to eql("Fixed (#{reference}.)")
    end

    it 'ignores invalid issue IDs' do
      invalid = invalidate_reference(reference)
      exp = act = "Fixed #{invalid}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("Issue #{reference}")
      expect(doc.css('a').first.attr('title')).to eq issue.title
    end

    it 'escapes the title attribute' do
      issue.update_attribute(:title, %{"></a>whatever<a title="})

      doc = reference_filter("Issue #{reference}")
      expect(doc.text).to eq "Issue #{reference}"
    end

    it 'renders non-HTML tooltips' do
      doc = reference_filter("Issue #{reference}")

      expect(doc.at_css('a')).not_to have_attribute('data-html')
    end

    it 'includes default classes' do
      doc = reference_filter("Issue #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Issue #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-issue attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-issue')
      expect(link.attr('data-issue')).to eq issue.id.to_s
    end

    it 'includes a data-original attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-original')
      expect(link.attr('data-original')).to eq reference
    end

    it 'does not escape the data-original attribute' do
      inner_html = 'element <code>node</code> inside'
      doc = reference_filter(%{<a href="#{reference}">#{inner_html}</a>})
      expect(doc.children.first.attr('data-original')).to eq inner_html
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Issue #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq issue_path
    end

    it 'does not process links containing issue numbers followed by text' do
      href = "#{reference}st"
      doc = reference_filter("<a href='#{href}'></a>")
      link = doc.css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:reference) { "#{project2.full_path}##{issue.iid}" }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public) }

    it_behaves_like 'a reference containing an element node'

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(described_class).to receive(:find_object)
        .with(project2, issue.iid)
        .and_return(nil)

      exp = act = "Issue #{reference}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.full_path}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.full_path}##{issue.iid}.)")
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let(:reference) { "#{project2.full_path}##{issue.iid}" }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:namespace) { create(:namespace) }

    it_behaves_like 'a reference containing an element node'

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(described_class).to receive(:find_object)
        .with(project2, issue.iid)
        .and_return(nil)

      exp = act = "Issue #{reference}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.path}##{issue.iid}.)")
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project shorthand reference' do
    let(:reference) { "#{project2.path}##{issue.iid}" }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:namespace) { create(:namespace) }

    it_behaves_like 'a reference containing an element node'

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(described_class).to receive(:find_object)
        .with(project2, issue.iid)
        .and_return(nil)

      exp = act = "Issue #{reference}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.path}##{issue.iid}.)")
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project URL reference' do
    let(:reference) { issue_url + "#note_123" }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:namespace) { create(:namespace, name: 'cross-reference') }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'link with trailing slash' do
      doc = reference_filter("Fixed (#{issue_url + "/"}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(issue.to_reference(project))}</a>\.\)})
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(issue.to_reference(project))} \(comment 123\)</a>\.\)})
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end
  end

  context 'cross-project reference in link href' do
    let(:reference_link) { %{<a href="#{reference}">Reference</a>} }
    let(:reference) { issue.to_reference(project) }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:namespace) { create(:namespace, name: 'cross-reference') }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference_link}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference_link}.)")

      expect(doc.to_html).to match(%r{\(<a.+>Reference</a>\.\)})
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference_link}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end
  end

  context 'cross-project URL in link href' do
    let(:reference_link) { %{<a href="#{reference}">Reference</a>} }
    let(:reference) { "#{issue_url + "#note_123"}" }
    let(:issue)     { create(:issue, project: project2) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:namespace) { create(:namespace, name: 'cross-reference') }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference_link}")

      expect(doc.css('a').first.attr('href'))
        .to eq issue_url + "#note_123"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference_link}.)")

      expect(doc.to_html).to match(%r{\(<a.+>Reference</a>\.\)})
    end

    it 'includes default classes' do
      doc = reference_filter("Fixed (#{reference_link}.)")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue has-tooltip'
    end
  end

  context 'when processing a link to the designs tab' do
    let(:designs_tab_url) { url_for_designs(issue) }
    let(:input_text) { "See #{designs_tab_url}" }

    subject(:link) { reference_filter(input_text).css('a').first }

    before do
      enable_design_management
    end

    it 'includes the word "designs" after the reference in the text content', :aggregate_failures do
      expect(link.attr('title')).to eq(issue.title)
      expect(link.attr('href')).to eq(designs_tab_url)
      expect(link.text).to eq("#{issue.to_reference} (designs)")
    end

    context 'design management is not available' do
      before do
        enable_design_management(false)
      end

      it 'links to the issue, but not to the designs tab' do
        expect(link.text).to eq(issue.to_reference)
      end
    end
  end

  context 'group context' do
    let(:group) { create(:group) }
    let(:context) { { project: nil, group: group } }

    it 'ignores shorthanded issue reference' do
      reference = "##{issue.iid}"
      text = "Fixed #{reference}"

      expect(reference_filter(text, context).to_html).to eq(text)
    end

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(described_class).to receive(:find_object)
        .with(project, issue.iid)
        .and_return(nil)

      reference = "#{project.full_path}##{issue.iid}"
      text = "Issue #{reference}"

      expect(reference_filter(text, context).to_html).to eq(text)
    end

    it 'links to a valid reference for complete cross-reference' do
      reference = "#{project.full_path}##{issue.iid}"
      doc = reference_filter("See #{reference}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq(issue_url)
      expect(link.text).to include("#{project.full_path}##{issue.iid}")
    end

    it 'ignores reference for shorthand cross-reference' do
      reference = "#{project.path}##{issue.iid}"
      text = "See #{reference}"

      expect(reference_filter(text, context).to_html).to eq(text)
    end

    it 'links to a valid reference for url cross-reference' do
      reference = issue_url + "#note_123"

      doc = reference_filter("See #{reference}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq(issue_url + "#note_123")
      expect(link.text).to include("#{project.full_path}##{issue.iid}")
    end

    it 'links to a valid reference for cross-reference in link href' do
      reference = "#{issue_url + "#note_123"}"
      reference_link = %{<a href="#{reference}">Reference</a>}

      doc = reference_filter("See #{reference_link}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq(issue_url + "#note_123")
      expect(link.text).to include('Reference')
    end

    it 'links to a valid reference for issue reference in the link href' do
      reference = issue.to_reference(group)
      reference_link = %{<a href="#{reference}">Reference</a>}
      doc = reference_filter("See #{reference_link}", context)

      link = doc.css('a').first
      expect(link.attr('href')).to eq(issue_url)
      expect(link.text).to include('Reference')
    end
  end

  describe '.references_in' do
    let(:merge_request) { create(:merge_request) }

    it 'yields valid references' do
      expect do |b|
        described_class.new('', project: nil).references_in(issue.to_reference, &b)
      end.to yield_with_args(issue.to_reference, issue.iid, nil, nil, MatchData)
    end

    it "doesn't yield invalid references" do
      expect do |b|
        described_class.new('', project: nil).references_in('#0', &b)
      end.not_to yield_control
    end

    it "doesn't yield unsupported references" do
      expect do |b|
        described_class.new('', project: nil).references_in(merge_request.to_reference, &b)
      end.not_to yield_control
    end
  end

  describe '#object_link_text_extras' do
    before do
      enable_design_management(enabled)
    end

    let(:current_user) { project.owner }
    let(:enabled) { true }
    let(:matches) { Issue.link_reference_pattern.match(input_text) }
    let(:extras) { subject.object_link_text_extras(issue, matches) }

    subject { filter_instance }

    context 'the link does not go to the designs tab' do
      let(:input_text) { Gitlab::Routing.url_helpers.project_issue_url(issue.project, issue) }

      it 'does not include designs' do
        expect(extras).not_to include('designs')
      end
    end

    context 'the link goes to the designs tab' do
      let(:input_text) { url_for_designs(issue) }

      it 'includes designs' do
        expect(extras).to include('designs')
      end

      context 'design management is disabled' do
        let(:enabled) { false }

        it 'does not include designs in the extras' do
          expect(extras).not_to include('designs')
        end
      end
    end
  end
end

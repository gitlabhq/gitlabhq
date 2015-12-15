require 'spec_helper'

describe Banzai::Filter::IssueReferenceFilter, lib: true do
  include FilterSpecHelper

  def helper
    IssuesHelper
  end

  let(:project) { create(:empty_project, :public) }
  let(:issue)   { create(:issue, project: project) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Issue #{issue.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'internal reference' do
    let(:reference) { issue.to_reference }

    it 'ignores valid references when using non-default tracker' do
      expect(project).to receive(:get_issue).with(issue.iid).and_return(nil)

      exp = act = "Issue #{reference}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = reference_filter("Fixed #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
    end

    it 'ignores invalid issue IDs' do
      invalid = invalidate_reference(reference)
      exp = act = "Fixed #{invalid}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("Issue #{reference}")
      expect(doc.css('a').first.attr('title')).to eq "Issue: #{issue.title}"
    end

    it 'escapes the title attribute' do
      issue.update_attribute(:title, %{"></a>whatever<a title="})

      doc = reference_filter("Issue #{reference}")
      expect(doc.text).to eq "Issue #{reference}"
    end

    it 'includes default classes' do
      doc = reference_filter("Issue #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue'
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

    it 'supports an :only_path context' do
      doc = reference_filter("Issue #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq helper.url_for_issue(issue.iid, project, only_path: true)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("Fixed #{reference}")
      expect(result[:references][:issue]).to eq [issue]
    end
  end

  context 'cross-project reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { issue.to_reference(project) }

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(Project).to receive(:get_issue).
        with(issue.iid).and_return(nil)

      exp = act = "Issue #{reference}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("Fixed #{reference}")
      expect(result[:references][:issue]).to eq [issue]
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { helper.url_for_issue(issue.iid, project2) + "#note_123" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq reference
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(issue.to_reference(project))} \(comment 123\)<\/a>\.\)/)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("Fixed #{reference}")
      expect(result[:references][:issue]).to eq [issue]
    end
  end

  context 'cross-project reference in link href' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { %Q{<a href="#{issue.to_reference(project)}">Reference</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>Reference<\/a>\.\)/)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("Fixed #{reference}")
      expect(result[:references][:issue]).to eq [issue]
    end
  end

  context 'cross-project URL in link href' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { %Q{<a href="#{helper.url_for_issue(issue.iid, project2) + "#note_123"}">Reference</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project2) + "#note_123"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>Reference<\/a>\.\)/)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("Fixed #{reference}")
      expect(result[:references][:issue]).to eq [issue]
    end
  end
end

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
    it_behaves_like 'a reference containing an element node'

    let(:reference) { issue.to_reference }

    it 'ignores valid references when using non-default tracker' do
      allow(project).to receive(:default_issues_tracker?).and_return(false)

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
      expect(doc.css('a').first.attr('title')).to eq issue.title
    end

    it 'escapes the title attribute' do
      issue.update_attribute(:title, %{"></a>whatever<a title="})

      doc = reference_filter("Issue #{reference}")
      expect(doc.text).to eq "Issue #{reference}"
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
      expect(link).to eq helper.url_for_issue(issue.iid, project, only_path: true)
    end

    it 'does not process links containing issue numbers followed by text' do
      href = "#{reference}st"
      doc = reference_filter("<a href='#{href}'></a>")
      link = doc.css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'cross-project reference' do
    it_behaves_like 'a reference containing an element node'

    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { issue.to_reference(project) }

    it 'ignores valid references when cross-reference project uses external tracker' do
      expect_any_instance_of(described_class).to receive(:find_object).
        with(project2, issue.iid).
        and_return(nil)

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

    it 'ignores out-of-bounds issue IDs on the referenced project' do
      exp = act = "Fixed ##{Gitlab::Database::MAX_INT_VALUE + 1}"

      expect(reference_filter(act).to_html).to eq exp
    end

    context 'with Redmine enabled on source project' do
      let(:project) { create(:redmine_project, :public, namespace: namespace) }

      it 'links to a valid reference' do
        doc = reference_filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq(helper.url_for_issue(issue.iid, issue.project))
      end
    end

    context 'with JIRA enabled on source project' do
      let(:project) { create(:jira_project, :public, namespace: namespace) }

      it 'links to a valid reference' do
        doc = reference_filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq(helper.url_for_issue(issue.iid, issue.project))
      end
    end
  end

  context 'cross-project URL reference' do
    it_behaves_like 'a reference containing an element node'

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

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq(reference)
    end
  end

  context 'cross-project reference in link href' do
    it_behaves_like 'a reference containing an element node'

    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { issue.to_reference(project) }
    let(:reference_link) { %{<a href="#{reference}">Reference</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference_link}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference_link}.)")
      expect(doc.to_html).to match(/\(<a.+>Reference<\/a>\.\)/)
    end
  end

  context 'cross-project URL in link href' do
    it_behaves_like 'a reference containing an element node'

    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { "#{helper.url_for_issue(issue.iid, project2) + "#note_123"}" }
    let(:reference_link) { %{<a href="#{reference}">Reference</a>} }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference_link}")

      expect(doc.css('a').first.attr('href')).
        to eq helper.url_for_issue(issue.iid, project2) + "#note_123"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference_link}.)")
      expect(doc.to_html).to match(/\(<a.+>Reference<\/a>\.\)/)
    end
  end

  describe '#issues_per_Project' do
    context 'using an internal issue tracker' do
      it 'returns a Hash containing the issues per project' do
        doc = Nokogiri::HTML.fragment('')
        filter = described_class.new(doc, project: project)

        expect(filter).to receive(:projects_per_reference).
          and_return({ project.path_with_namespace => project })

        expect(filter).to receive(:references_per_project).
          and_return({ project.path_with_namespace => Set.new([issue.iid]) })

        expect(filter.issues_per_project).
          to eq({ project => { issue.iid => issue } })
      end
    end

    context 'using an external issue tracker' do
      it 'returns a Hash containing the issues per project' do
        doc = Nokogiri::HTML.fragment('')
        filter = described_class.new(doc, project: project)

        expect(project).to receive(:default_issues_tracker?).and_return(false)

        expect(filter).to receive(:projects_per_reference).
          and_return({ project.path_with_namespace => project })

        expect(filter).to receive(:references_per_project).
          and_return({ project.path_with_namespace => Set.new([1]) })

        expect(filter.issues_per_project[project][1]).
          to be_an_instance_of(ExternalIssue)
      end
    end
  end
end

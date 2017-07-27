require 'spec_helper'

describe Banzai::Filter::IssueReferenceFilter do
  include FilterSpecHelper

  def helper
    IssuesHelper
  end

  let(:project) { create(:empty_project, :public) }
  let(:issue)  { create(:issue, project: project) }

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
    it_behaves_like 'a reference containing an element node'

    let(:reference) { "##{issue.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("Fixed #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq helper.url_for_issue(issue.iid, project)
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

  context 'cross-project / cross-namespace complete reference' do
    it_behaves_like 'a reference containing an element node'

    let(:project2)  { create(:empty_project, :public) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { "#{project2.path_with_namespace}##{issue.iid}" }

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
        .to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path_with_namespace}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.path_with_namespace}##{issue.iid}.)")
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project / same-namespace complete reference' do
    it_behaves_like 'a reference containing an element node'

    let(:namespace) { create(:namespace) }
    let(:project)   { create(:empty_project, :public, namespace: namespace) }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { "#{project2.path_with_namespace}##{issue.iid}" }

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
        .to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.path}##{issue.iid}.)")
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project shorthand reference' do
    it_behaves_like 'a reference containing an element node'

    let(:namespace) { create(:namespace) }
    let(:project)   { create(:empty_project, :public, namespace: namespace) }
    let(:project2)  { create(:empty_project, :public, namespace: namespace) }
    let(:issue)     { create(:issue, project: project2) }
    let(:reference) { "#{project2.path}##{issue.iid}" }

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
        .to eq helper.url_for_issue(issue.iid, project2)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}##{issue.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eq("Fixed (#{project2.path}##{issue.iid}.)")
    end

    it 'ignores invalid issue IDs on the referenced project' do
      exp = act = "Fixed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
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

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(issue.to_reference(project))} \(comment 123\)<\/a>\.\)/)
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

      expect(doc.css('a').first.attr('href'))
        .to eq helper.url_for_issue(issue.iid, project2)
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

      expect(doc.css('a').first.attr('href'))
        .to eq helper.url_for_issue(issue.iid, project2) + "#note_123"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference_link}.)")
      expect(doc.to_html).to match(/\(<a.+>Reference<\/a>\.\)/)
    end
  end

  describe '#issues_per_project' do
    context 'using an internal issue tracker' do
      it 'returns a Hash containing the issues per project' do
        doc = Nokogiri::HTML.fragment('')
        filter = described_class.new(doc, project: project)

        expect(filter).to receive(:projects_per_reference)
          .and_return({ project.path_with_namespace => project })

        expect(filter).to receive(:references_per_project)
          .and_return({ project.path_with_namespace => Set.new([issue.iid]) })

        expect(filter.issues_per_project)
          .to eq({ project => { issue.iid => issue } })
      end
    end
  end

  describe '.references_in' do
    let(:merge_request)  { create(:merge_request) }

    it 'yields valid references' do
      expect do |b|
        described_class.references_in(issue.to_reference, &b)
      end.to yield_with_args(issue.to_reference, issue.iid, nil, nil, MatchData)
    end

    it "doesn't yield invalid references" do
      expect do |b|
        described_class.references_in('#0', &b)
      end.not_to yield_control
    end

    it "doesn't yield unsupported references" do
      expect do |b|
        described_class.references_in(merge_request.to_reference, &b)
      end.not_to yield_control
    end
  end
end

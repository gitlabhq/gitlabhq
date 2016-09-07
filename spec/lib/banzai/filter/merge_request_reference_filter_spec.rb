require 'spec_helper'

describe Banzai::Filter::MergeRequestReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project) { create(:project, :public) }
  let(:merge)   { create(:merge_request, source_project: project) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Merge #{merge.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'internal reference' do
    let(:reference) { merge.to_reference }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_merge_request_url(project.namespace, project, merge)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Merge (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
    end

    it 'ignores invalid merge IDs' do
      exp = act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'ignores out-of-bounds merge request IDs on the referenced project' do
      exp = act = "Merge !#{Gitlab::Database::MAX_INT_VALUE + 1}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("Merge #{reference}")
      expect(doc.css('a').first.attr('title')).to eq merge.title
    end

    it 'escapes the title attribute' do
      merge.update_attribute(:title, %{"></a>whatever<a title="})

      doc = reference_filter("Merge #{reference}")
      expect(doc.text).to eq "Merge #{reference}"
    end

    it 'includes default classes' do
      doc = reference_filter("Merge #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-merge_request has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Merge #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-merge-request attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-merge-request')
      expect(link.attr('data-merge-request')).to eq merge.id.to_s
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Merge #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.namespace_project_merge_request_url(project.namespace, project, merge, only_path: true)
    end
  end

  context 'cross-project reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:merge)     { create(:merge_request, source_project: project2) }
    let(:reference) { merge.to_reference(project) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq urls.namespace_project_merge_request_url(project2.namespace,
                                                      project, merge)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Merge (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
    end

    it 'ignores invalid merge IDs on the referenced project' do
      exp = act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:merge)     { create(:merge_request, source_project: project2, target_project: project2) }
    let(:reference) { urls.namespace_project_merge_request_url(project2.namespace, project2, merge) + '/diffs#note_123' }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq reference
    end

    it 'links with adjacent text' do
      doc = reference_filter("Merge (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(merge.to_reference(project))} \(diffs, comment 123\)<\/a>\.\)/)
    end
  end
end

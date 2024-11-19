# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::MergeRequestReferenceFilter, feature_category: :code_review_workflow do
  include FilterSpecHelper

  let(:project) { create(:project, :public) }
  let(:merge)   { create(:merge_request, source_project: project) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Merge #{merge.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
    end
  end

  describe 'performance' do
    let(:another_merge) { create(:merge_request, source_project: project, source_branch: 'fix') }

    it 'does not have a N+1 query problem' do
      single_reference = "Merge request #{merge.to_reference}"
      multiple_references = "Merge requests #{merge.to_reference} and #{another_merge.to_reference}"

      control = ActiveRecord::QueryRecorder.new { reference_filter(single_reference).to_html }

      expect { reference_filter(multiple_references).to_html }.not_to exceed_query_limit(control)
    end
  end

  describe 'all references' do
    let(:doc) { reference_filter(merge.to_reference) }
    let(:tag_el) { doc.css('a').first }

    it 'adds merge request iid' do
      expect(tag_el["data-iid"]).to eq(merge.iid.to_s)
    end

    it 'adds project data attribute with project id' do
      expect(tag_el["data-project-path"]).to eq(project.full_path)
    end

    it 'does not add `has-tooltip` class' do
      expect(tag_el["class"]).not_to include('has-tooltip')
    end
  end

  context 'internal reference' do
    let(:reference) { merge.to_reference }
    let(:merge_request_url) { urls.project_merge_request_url(project, merge) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls
        .project_merge_request_url(project, merge)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Merge (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(reference)}</a>\.\)})
    end

    it 'ignores invalid merge IDs' do
      act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'ignores out-of-bounds merge request IDs on the referenced project' do
      act = "Merge !#{Gitlab::Database::MAX_INT_VALUE + 1}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'has the MR title in the title attribute' do
      doc = reference_filter("Merge #{reference}")
      expect(doc.css('a').first.attr('title')).to eq(merge.title)
    end

    it 'escapes the title attribute' do
      merge.update_attribute(:title, %("></a>whatever<a title="))

      doc = reference_filter("Merge #{reference}")
      expect(doc.text).to eq "Merge #{reference}"
    end

    it 'includes default classes, without tooltip' do
      doc = reference_filter("Merge #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-merge_request'
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

    it 'includes a data-reference-format attribute' do
      doc = reference_filter("Merge #{reference}+")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(merge_request_url)
    end

    it 'includes a data-reference-format attribute for URL references' do
      doc = reference_filter("Merge #{merge_request_url}+")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(merge_request_url)
    end

    it 'includes a data-reference-format attribute for extended summary URL references' do
      doc = reference_filter("Merge #{merge_request_url}+s")
      link = doc.css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+s')
      expect(link.attr('href')).to eq(merge_request_url)
    end

    it 'supports an :only_path context' do
      doc = reference_filter("Merge #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r{https?://}
      expect(link).to eq urls.project_merge_request_url(project, merge, only_path: true)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:project2)          { create(:project, :public) }
    let(:merge)             { create(:merge_request, source_project: project2) }
    let(:reference)         { "#{project2.full_path}!#{merge.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_merge_request_url(project2, merge)
    end

    it 'link has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.css('a').first.text).to eq(reference)
    end

    it 'has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.text).to eq("Merge (#{reference}.)")
    end

    it 'has correct data attributes' do
      doc = reference_filter("Merge (#{reference}.)")

      link = doc.css('a').first

      expect(link.attr('data-project')).to eq project2.id.to_s
      expect(link.attr('data-project-path')).to eq project2.full_path
      expect(link.attr('data-iid')).to eq merge.iid.to_s
    end

    it 'ignores invalid merge IDs on the referenced project' do
      act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let!(:merge)    { create(:merge_request, source_project: project2) }
    let(:reference) { "#{project2.full_path}!#{merge.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_merge_request_url(project2, merge)
    end

    it 'link has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.css('a').first.text).to eq("#{project2.path}!#{merge.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.text).to eq("Merge (#{project2.path}!#{merge.iid}.)")
    end

    it 'ignores invalid merge IDs on the referenced project' do
      act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project shorthand reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, :public, namespace: namespace) }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let!(:merge)    { create(:merge_request, source_project: project2) }
    let(:reference) { "#{project2.path}!#{merge.iid}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_merge_request_url(project2, merge)
    end

    it 'link has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.css('a').first.text).to eq("#{project2.path}!#{merge.iid}")
    end

    it 'has valid text' do
      doc = reference_filter("Merge (#{reference}.)")

      expect(doc.text).to eq("Merge (#{project2.path}!#{merge.iid}.)")
    end

    it 'ignores invalid merge IDs on the referenced project' do
      act = "Merge #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'URL reference for a commit' do
    let(:mr) { create(:merge_request) }
    let(:reference) do
      urls.project_merge_request_url(mr.project, mr) + "/diffs?commit_id=#{mr.diff_head_sha}"
    end

    let(:commit) { mr.commits.find { |commit| commit.sha == mr.diff_head_sha } }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'commit ref tag is valid' do
      doc = reference_filter("See #{reference}")
      commit_ref_tag = doc.css('a').first.css('span.gfm.gfm-commit')

      expect(commit_ref_tag.text).to eq(commit.short_id)
    end

    it 'has valid text' do
      doc = reference_filter("See #{reference}")

      expect(doc.text).to eq("See #{mr.to_reference(full: true)} (#{commit.short_id})")
    end

    it 'ignores invalid commit short_ids on link text' do
      invalidate_commit_reference =
        urls.project_merge_request_url(mr.project, mr) + "/diffs?commit_id=12345678"
      doc = reference_filter("See #{invalidate_commit_reference}")

      expect(doc.text).to eq("See #{mr.to_reference(full: true)} (diffs)")
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:merge)     { create(:merge_request, source_project: project2, target_project: project2) }
    let(:reference) { urls.project_merge_request_url(project2, merge) + '/diffs#note_123' }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'links with adjacent text' do
      doc = reference_filter("Merge (#{reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>#{Regexp.escape(merge.to_reference(project))} \(diffs, comment 123\)</a>\.\)})
    end
  end

  context 'group context' do
    it 'links to a valid reference' do
      reference = "#{project.full_path}!#{merge.iid}"

      result = reference_filter("See #{reference}", { project: nil, group: create(:group) })

      expect(result.css('a').first.attr('href')).to eq(urls.project_merge_request_url(project, merge))
    end
  end

  context 'checking N+1' do
    let(:merge_request1) { create(:merge_request, source_project: project, source_branch: 'branch1') }
    let(:merge_request2) { create(:merge_request, source_project: project, source_branch: 'branch2') }

    it 'does not have a N+1 query problem' do
      single_reference = "Merge request #{merge_request1.to_reference}"
      multiple_references = "Merge requests #{merge_request1.to_reference} and #{merge_request2.to_reference}"

      control = ActiveRecord::QueryRecorder.new { reference_filter(single_reference).to_html }

      expect { reference_filter(multiple_references).to_html }.not_to exceed_query_limit(control)
    end
  end
end

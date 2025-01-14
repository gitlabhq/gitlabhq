# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::CommitReferenceFilter, feature_category: :source_code_management do
  include FilterSpecHelper

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:commit)  { project.commit }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w[pre code a style].each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      act = "<#{elem}>Commit #{commit.id}</#{elem}>"
      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'internal reference' do
    let(:reference) { commit.id }

    # Let's test a variety of commit SHA sizes just to be paranoid
    [7, 8, 12, 18, 20, 32, 40].each do |size|
      it "links to a valid reference of #{size} characters" do
        doc = reference_filter("See #{reference[0...size]}")

        expect(doc.css('a').first.text).to eq commit.short_id
        expect(doc.css('a').first.attr('href'))
          .to eq urls.project_commit_url(project, reference)
      end
    end

    # This solves https://gitlab.com/gitlab-org/gitlab/-/issues/450246
    it "does not render link when reference is ending a word" do
      doc = reference_filter("Hello Wo#{reference[0...7]}")

      expect(doc.css('a')).to be_empty
    end

    # This solves https://gitlab.com/gitlab-org/gitlab/-/issues/450246
    it "does not render link when reference is starting a word" do
      doc = reference_filter("Hello #{reference[0...7]}ld")

      expect(doc.css('a')).to be_empty
    end

    it 'always uses the short ID as the link text' do
      doc = reference_filter("See #{commit.id}")
      expect(doc.text).to eq "See #{commit.short_id}"

      doc = reference_filter("See #{commit.id[0...7]}")
      expect(doc.text).to eq "See #{commit.short_id}"
    end

    it 'links with adjacent text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{commit.short_id}</a>\.\)})
    end

    it 'ignores invalid commit IDs' do
      invalid = invalidate_reference(reference)
      act = "See #{invalid}"

      expect(reference_filter(act).to_html).to include act
    end

    it 'includes a title attribute' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('title')).to eq commit.title
    end

    it 'escapes the title attribute' do
      allow_next_instance_of(Commit) do |instance|
        allow(instance).to receive(:title).and_return(%("></a>whatever<a title="))
      end

      doc = reference_filter("See #{reference}")
      expect(doc.text).to eq "See #{commit.short_id}"
    end

    it 'includes default classes' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-commit attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-commit')
      expect(link.attr('data-commit')).to eq commit.id
    end

    it 'supports an :only_path context' do
      doc = reference_filter("See #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r{https?://}
      expect(link).to eq urls.project_commit_url(project, reference, only_path: true)
    end

    context "in merge request context" do
      let(:noteable) { create(:merge_request, target_project: project, source_project: project) }
      let(:commit) { noteable.commits.first }

      it 'handles merge request contextual commit references' do
        url = urls.diffs_project_merge_request_url(project, noteable, commit_id: commit.id)
        doc = reference_filter("See #{reference}", noteable: noteable)

        expect(doc.css('a').first[:href]).to eq(url)
      end

      context "a doc with many (29) strings that could be SHAs" do
        let!(:oids) { noteable.commits.collect(&:id) }

        it 'makes only a single request to Gitaly' do
          expect(Gitlab::GitalyClient).to receive(:allow_n_plus_1_calls).exactly(0).times
          expect(Gitlab::Git::Commit).to receive(:batch_by_oid).once.and_call_original

          reference_filter("A big list of SHAs #{oids.join(', ')}", noteable: noteable)
        end
      end
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { "#{project2.full_path}@#{commit.short_id}" }

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.full_path}@#{commit.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{project2.full_path}@#{commit.short_id}.)")
    end

    context 'when absolute path namespace is provided instead of project' do
      let(:reference) { "/#{namespace.full_path}@#{commit.short_id}" }

      it 'does not replace this reference with a link' do
        doc = reference_filter("See (#{reference}.)")

        expect(doc.css('a')).to be_empty
        expect(doc.text).to eql("See (/#{namespace.full_path}@#{commit.short_id}.)")
      end
    end

    it 'ignores invalid commit IDs on the referenced project' do
      act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, namespace: namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { "#{project2.full_path}@#{commit.short_id}" }

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}@#{commit.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{project2.path}@#{commit.short_id}.)")
    end

    it 'ignores invalid commit IDs on the referenced project' do
      act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project shorthand reference' do
    let(:namespace) { create(:namespace) }
    let(:project)   { create(:project, namespace: namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { "#{project2.full_path}@#{commit.short_id}" }

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text).to eql("#{project2.path}@#{commit.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text).to eql("See (#{project2.path}@#{commit.short_id}.)")
    end

    it 'ignores invalid commit IDs on the referenced project' do
      act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { urls.project_commit_url(project2, commit.id) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_commit_url(project2, commit.id)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.to_html).to match(%r{\(<a.+>#{commit.reference_link_text(project)}</a>\.\)})
    end

    it 'ignores invalid commit IDs on the referenced project' do
      act = "Committed #{invalidate_reference(reference)}"
      expect(reference_filter(act).to_html).to match(%r{<a.+>#{Regexp.escape(invalidate_reference(reference))}</a>})
    end
  end

  context 'URL reference for a commit patch' do
    let(:namespace) { create(:namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:link)      { urls.project_commit_url(project2, commit.id) }
    let(:extension) { '.patch' }
    let(:reference) { link + extension }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'has valid text' do
      doc = reference_filter("See #{reference}")

      expect(doc.text).to eq("See #{commit.reference_link_text(project)} (patch)")
    end

    it 'does not link to patch when extension match is after the path' do
      invalidate_commit_reference = reference_filter("#{link}/builds.patch")

      doc = reference_filter("See (#{invalidate_commit_reference})")

      expect(doc.css('a').first.attr('href')).to eq "#{link}/builds"
      expect(doc.text).to eq("See (#{commit.reference_link_text(project)} (builds).patch)")
    end
  end

  context 'group context' do
    let(:context) { { project: nil, group: create(:group) } }

    it 'ignores internal references' do
      act = "See #{commit.id}"

      expect(reference_filter(act, context).to_html).to include act
    end

    it 'links to a valid reference' do
      act = "See #{project.full_path}@#{commit.id}"

      expect(reference_filter(act, context).css('a').first.text).to eql("#{project.full_path}@#{commit.short_id}")
    end
  end

  context 'when Commit.reference_pattern causes a long scanning period' do
    it 'timesout and rescues in filter' do
      stub_const("Banzai::Filter::References::AbstractReferenceFilter::RENDER_TIMEOUT", 0.1)
      markdown = 'a-' * 55000

      expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception)

      reference_filter(markdown)
    end
  end

  context 'checking N+1' do
    let(:namespace2)        { create(:namespace) }
    let(:namespace3)        { create(:namespace) }
    let(:project2)          { create(:project, :public, :repository, namespace: namespace2) }
    let(:project3)          { create(:project, :public, :repository, namespace: namespace3) }
    let(:commit2)           { project2.commit }
    let(:commit3)           { project3.commit }
    let(:commit_reference)  { commit.to_reference }
    let(:commit2_reference) { commit2.to_reference(full: true) }
    let(:commit3_reference) { commit3.to_reference(full: true) }

    it 'does not have N+1 per multiple references per project', :use_sql_query_cache do
      markdown = commit_reference.to_s
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown)
      end

      expect(control.count).to eq 0

      markdown = "#{commit_reference} 8b95f2f1 8b95f2f2 8b95f2f3 #{commit2_reference} #{commit3_reference}"

      # Commits are not DB entries, they are on the project itself.
      # 1 for for routes to find routes.source_id of projects matching paths
      # 1 for projects belonging to the above routes
      # 1 for preloading routes of the projects
      # 1 for loading the namespaces associated to the project
      # 1 for loading the routes associated with the namespace
      # Total = 5
      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control).with_threshold(5)
    end
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { "#{commit.id} #{commit.id} #{commit.id}" }
    let(:ends_with) { "</a> #{commit.id}" }
  end
end

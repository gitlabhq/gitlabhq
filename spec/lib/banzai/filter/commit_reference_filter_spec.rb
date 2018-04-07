require 'spec_helper'

describe Banzai::Filter::CommitReferenceFilter do
  include FilterSpecHelper

  let(:project) { create(:project, :public, :repository) }
  let(:commit)  { project.commit }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Commit #{commit.id}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
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
      exp = act = "See #{invalid}"

      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('title')).to eq commit.title
    end

    it 'escapes the title attribute' do
      allow_any_instance_of(Commit).to receive(:title).and_return(%{"></a>whatever<a title="})

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

      expect(link).not_to match %r(https?://)
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

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
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
      exp = act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
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
      exp = act = "Committed #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
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
end

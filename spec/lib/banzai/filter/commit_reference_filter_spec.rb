require 'spec_helper'

describe Banzai::Filter::CommitReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project) { create(:project, :public) }
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
        expect(doc.css('a').first.attr('href')).
          to eq urls.namespace_project_commit_url(project.namespace, project, reference)
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
      expect(doc.to_html).to match(/\(<a.+>#{commit.short_id}<\/a>\.\)/)
    end

    it 'ignores invalid commit IDs' do
      invalid = invalidate_reference(reference)
      exp = act = "See #{invalid}"

      expect(project).to receive(:valid_repo?).and_return(true)
      expect(project.repository).to receive(:commit).with(invalid)
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes a title attribute' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('title')).to eq commit.link_title
    end

    it 'escapes the title attribute' do
      allow_any_instance_of(Commit).to receive(:title).and_return(%{"></a>whatever<a title="})

      doc = reference_filter("See #{reference}")
      expect(doc.text).to eq "See #{commit.short_id}"
    end

    it 'includes default classes' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit'
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
      expect(link).to eq urls.namespace_project_commit_url(project.namespace, project, reference, only_path: true)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("See #{reference}")
      expect(result[:references][:commit]).not_to be_empty
    end
  end

  context 'cross-project reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { commit.to_reference(project) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq urls.namespace_project_commit_url(project2.namespace, project2, commit.id)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")

      exp = Regexp.escape(project2.to_reference)
      expect(doc.to_html).to match(/\(<a.+>#{exp}@#{commit.short_id}<\/a>\.\)/)
    end

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Committed #{invalidate_reference(reference)}"
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("See #{reference}")
      expect(result[:references][:commit]).not_to be_empty
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace, name: 'cross-reference') }
    let(:project2)  { create(:project, :public, namespace: namespace) }
    let(:commit)    { project2.commit }
    let(:reference) { urls.namespace_project_commit_url(project2.namespace, project2, commit.id) }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).
        to eq urls.namespace_project_commit_url(project2.namespace, project2, commit.id)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.to_html).to match(/\(<a.+>#{commit.reference_link_text(project)}<\/a>\.\)/)
    end

    it 'ignores invalid commit IDs on the referenced project' do
      act = "Committed #{invalidate_reference(reference)}"
      expect(reference_filter(act).to_html).to match(/<a.+>#{Regexp.escape(invalidate_reference(reference))}<\/a>/)
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("See #{reference}")
      expect(result[:references][:commit]).not_to be_empty
    end
  end
end

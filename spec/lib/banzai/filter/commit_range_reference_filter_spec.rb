require 'spec_helper'

describe Banzai::Filter::CommitRangeReferenceFilter do
  include FilterSpecHelper

  let(:project) { create(:project, :public, :repository) }
  let(:commit1) { project.commit("HEAD~2") }
  let(:commit2) { project.commit }

  let(:range)  { CommitRange.new("#{commit1.id}...#{commit2.id}", project) }
  let(:range2) { CommitRange.new("#{commit1.id}..#{commit2.id}", project) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>Commit Range #{range.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'internal reference' do
    let(:reference)  { range.to_reference }
    let(:reference2) { range2.to_reference }

    it 'links to a valid two-dot reference' do
      doc = reference_filter("See #{reference2}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_compare_url(project, range2.to_param)
    end

    it 'links to a valid three-dot reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_compare_url(project, range.to_param)
    end

    it 'links to a valid short ID' do
      reference = "#{commit1.short_id}...#{commit2.id}"
      reference2 = "#{commit1.id}...#{commit2.short_id}"

      exp = commit1.short_id + '...' + commit2.short_id

      expect(reference_filter("See #{reference}").css('a').first.text).to eq exp
      expect(reference_filter("See #{reference2}").css('a').first.text).to eq exp
    end

    it 'links with adjacent text' do
      doc = reference_filter("See (#{reference}.)")

      exp = Regexp.escape(range.reference_link_text)
      expect(doc.to_html).to match(%r{\(<a.+>#{exp}</a>\.\)})
    end

    it 'ignores invalid commit IDs' do
      exp = act = "See #{commit1.id.reverse}...#{commit2.id}"

      allow(project.repository).to receive(:commit).with(commit1.id.reverse)
      expect(reference_filter(act).to_html).to eq exp
    end

    it 'includes no title attribute' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('title')).to eq ""
    end

    it 'includes default classes' do
      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit_range has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-commit-range attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-commit-range')
      expect(link.attr('data-commit-range')).to eq range.to_s
    end

    it 'supports an :only_path option' do
      doc = reference_filter("See #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.project_compare_url(project, from: commit1.id, to: commit2.id, only_path: true)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:project2)  { create(:project, :public, :repository) }
    let(:reference) { "#{project2.full_path}@#{commit1.id}...#{commit2.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_compare_url(project2, range.to_param)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eql("#{project2.full_path}@#{commit1.short_id}...#{commit2.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eql("Fixed (#{project2.full_path}@#{commit1.short_id}...#{commit2.short_id}.)")
    end

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Fixed #{project2.full_path}@#{commit1.id.reverse}...#{commit2.id}"
      expect(reference_filter(act).to_html).to eq exp

      exp = act = "Fixed #{project2.full_path}@#{commit1.id}...#{commit2.id.reverse}"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project / same-namespace complete reference' do
    let(:namespace)         { create(:namespace) }
    let(:project)           { create(:project, :public, :repository, namespace: namespace) }
    let(:project2)          { create(:project, :public, :repository, path: "same-namespace", namespace: namespace) }
    let(:reference)         { "#{project2.path}@#{commit1.id}...#{commit2.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_compare_url(project2, range.to_param)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eql("#{project2.path}@#{commit1.short_id}...#{commit2.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eql("Fixed (#{project2.path}@#{commit1.short_id}...#{commit2.short_id}.)")
    end

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Fixed #{project2.path}@#{commit1.id.reverse}...#{commit2.id}"
      expect(reference_filter(act).to_html).to eq exp

      exp = act = "Fixed #{project2.path}@#{commit1.id}...#{commit2.id.reverse}"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project shorthand reference' do
    let(:namespace)         { create(:namespace) }
    let(:project)           { create(:project, :public, :repository, namespace: namespace) }
    let(:project2)          { create(:project, :public, :repository, path: "same-namespace", namespace: namespace) }
    let(:reference)         { "#{project2.path}@#{commit1.id}...#{commit2.id}" }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq urls.project_compare_url(project2, range.to_param)
    end

    it 'link has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eql("#{project2.path}@#{commit1.short_id}...#{commit2.short_id}")
    end

    it 'has valid text' do
      doc = reference_filter("Fixed (#{reference}.)")

      expect(doc.text).to eql("Fixed (#{project2.path}@#{commit1.short_id}...#{commit2.short_id}.)")
    end

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Fixed #{project2.path}@#{commit1.id.reverse}...#{commit2.id}"
      expect(reference_filter(act).to_html).to eq exp

      exp = act = "Fixed #{project2.path}@#{commit1.id}...#{commit2.id.reverse}"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'cross-project URL reference' do
    let(:namespace) { create(:namespace) }
    let(:project2)  { create(:project, :public, :repository, namespace: namespace) }
    let(:range)  { CommitRange.new("#{commit1.id}...master", project) }
    let(:reference) { urls.project_compare_url(project2, from: commit1.id, to: 'master') }

    before do
      range.project = project2
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href'))
        .to eq reference
    end

    it 'links with adjacent text' do
      doc = reference_filter("Fixed (#{reference}.)")

      exp = Regexp.escape(range.reference_link_text(project))
      expect(doc.to_html).to match(%r{\(<a.+>#{exp}</a>\.\)})
    end

    it 'ignores invalid commit IDs on the referenced project' do
      exp = act = "Fixed #{project2.to_reference}@#{commit1.id.reverse}...#{commit2.id}"
      expect(reference_filter(act).to_html).to eq exp

      exp = act = "Fixed #{project2.to_reference}@#{commit1.id}...#{commit2.id.reverse}"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'group context' do
    let(:context) { { project: nil, group: create(:group) } }

    it 'ignores internal references' do
      exp = act = "See #{range.to_reference}"

      expect(reference_filter(act, context).to_html).to eq exp
    end

    it 'links to a full-path reference' do
      reference = "#{project.full_path}@#{commit1.short_id}...#{commit2.short_id}"

      expect(reference_filter("See #{reference}", context).css('a').first.text).to eql(reference)
    end
  end
end

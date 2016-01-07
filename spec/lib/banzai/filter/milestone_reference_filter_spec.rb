require 'spec_helper'

describe Banzai::Filter::MilestoneReferenceFilter, lib: true do
  include FilterSpecHelper

  let(:project) { create(:project, :public) }
  let(:milestone)   { create(:milestone, project: project) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  %w(pre code a style).each do |elem|
    it "ignores valid references contained inside '#{elem}' element" do
      exp = act = "<#{elem}>milestone #{milestone.to_reference}</#{elem}>"
      expect(reference_filter(act).to_html).to eq exp
    end
  end

  context 'internal reference' do
    # Convert the Markdown link to only the URL, since these tests aren't run through the regular Markdown pipeline.
    # Milestone reference behavior in the full Markdown pipeline is tested elsewhere.
    let(:reference) { milestone.to_reference.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '\2') }

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.
        namespace_project_milestone_url(project.namespace, project, milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("milestone (#{reference}.)")
      expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(milestone.title)}<\/a>\.\)/)
    end

    it 'includes a title attribute' do
      doc = reference_filter("milestone #{reference}")
      expect(doc.css('a').first.attr('title')).to eq "Milestone: #{milestone.title}"
    end

    it 'escapes the title attribute' do
      milestone.update_attribute(:title, %{"></a>whatever<a title="})

      doc = reference_filter("milestone #{reference}")
      expect(doc.text).to eq "milestone #{milestone.title}"
    end

    it 'includes default classes' do
      doc = reference_filter("milestone #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-milestone'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("milestone #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-milestone attribute' do
      doc = reference_filter("See #{reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-milestone')
      expect(link.attr('data-milestone')).to eq milestone.id.to_s
    end

    it 'adds to the results hash' do
      result = reference_pipeline_result("milestone #{reference}")
      expect(result[:references][:milestone]).to eq [milestone]
    end
  end
end

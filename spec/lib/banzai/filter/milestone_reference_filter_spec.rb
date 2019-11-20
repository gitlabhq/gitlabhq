# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::MilestoneReferenceFilter do
  include FilterSpecHelper

  let(:parent_group) { create(:group, :public) }
  let(:group) { create(:group, :public, parent: parent_group) }
  let(:project) { create(:project, :public, group: group) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  shared_examples 'reference parsing' do
    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>milestone #{reference}</#{elem}>"
        expect(reference_filter(act).to_html).to eq exp
      end
    end

    it 'includes default classes' do
      doc = reference_filter("Milestone #{reference}")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-milestone has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{reference}")
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

    it 'supports an :only_path context' do
      doc = reference_filter("Milestone #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.milestone_path(milestone)
    end
  end

  shared_examples 'Integer-based references' do
    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.reference_link_text}</a>\.\)))
    end

    it 'ignores invalid milestone IIDs' do
      exp = act = "Milestone #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'String-based single-word references' do
    let(:reference) { "#{Milestone.reference_prefix}#{milestone.name}" }

    before do
      milestone.update!(name: 'gfm')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
      expect(doc.text).to eq "See #{milestone.reference_link_text}"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.reference_link_text}</a>\.\)))
    end

    it 'ignores invalid milestone names' do
      exp = act = "Milestone #{Milestone.reference_prefix}#{milestone.name.reverse}"

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'String-based multi-word references in quotes' do
    let(:reference) { milestone.to_reference(format: :name) }

    before do
      milestone.update!(name: 'gfm references')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
      expect(doc.text).to eq "See #{milestone.reference_link_text}"
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>#{milestone.reference_link_text}</a>\.\)))
    end

    it 'ignores invalid milestone names' do
      exp = act = %(Milestone #{Milestone.reference_prefix}"#{milestone.name.reverse}")

      expect(reference_filter(act).to_html).to eq exp
    end
  end

  shared_examples 'referencing a milestone in a link href' do
    let(:unquoted_reference) { "#{Milestone.reference_prefix}#{milestone.name}" }
    let(:link_reference) { %Q{<a href="#{unquoted_reference}">Milestone</a>} }

    before do
      milestone.update!(name: 'gfm')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{link_reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{link_reference}.)")
      expect(doc.to_html).to match(%r(\(<a.+>Milestone</a>\.\)))
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-milestone attribute' do
      doc = reference_filter("See #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-milestone')
      expect(link.attr('data-milestone')).to eq milestone.id.to_s
    end
  end

  shared_examples 'linking to a milestone as the entire link' do
    let(:unquoted_reference) { "#{Milestone.reference_prefix}#{milestone.name}" }
    let(:link) { urls.milestone_url(milestone) }
    let(:link_reference) { %Q{<a href="#{link}">#{link}</a>} }

    it 'replaces the link text with the milestone reference' do
      doc = reference_filter("See #{link}")

      expect(doc.css('a').first.text).to eq(unquoted_reference)
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-project')
      expect(link.attr('data-project')).to eq project.id.to_s
    end

    it 'includes a data-milestone attribute' do
      doc = reference_filter("See #{link_reference}")
      link = doc.css('a').first

      expect(link).to have_attribute('data-milestone')
      expect(link.attr('data-milestone')).to eq milestone.id.to_s
    end
  end

  shared_examples 'cross-project / cross-namespace complete reference' do
    let(:namespace)       { create(:namespace) }
    let(:another_project) { create(:project, :public, namespace: namespace) }
    let(:milestone)       { create(:milestone, project: another_project) }
    let(:reference)       { "#{another_project.full_path}%#{milestone.iid}" }
    let!(:result)         { reference_filter("See #{reference}") }

    it 'points to referenced project milestone page' do
      expect(result.css('a').first.attr('href')).to eq urls
        .project_milestone_url(another_project, milestone)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eq("#{milestone.reference_link_text} in #{another_project.full_path}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text)
        .to eq("See (#{milestone.reference_link_text} in #{another_project.full_path}.)")
    end

    it 'escapes the name attribute' do
      allow_next_instance_of(Milestone) do |instance|
        allow(instance).to receive(:title).and_return(%{"></a>whatever<a title="})
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{milestone.reference_link_text} in #{another_project.full_path}"
    end
  end

  shared_examples 'cross-project / same-namespace complete reference' do
    let(:namespace)       { create(:namespace) }
    let(:project)         { create(:project, :public, namespace: namespace) }
    let(:another_project) { create(:project, :public, namespace: namespace) }
    let(:milestone)       { create(:milestone, project: another_project) }
    let(:reference)       { "#{another_project.full_path}%#{milestone.iid}" }
    let!(:result)         { reference_filter("See #{reference}") }

    it 'points to referenced project milestone page' do
      expect(result.css('a').first.attr('href')).to eq urls
        .project_milestone_url(another_project, milestone)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eq("#{milestone.reference_link_text} in #{another_project.path}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text)
        .to eq("See (#{milestone.reference_link_text} in #{another_project.path}.)")
    end

    it 'escapes the name attribute' do
      allow_next_instance_of(Milestone) do |instance|
        allow(instance).to receive(:title).and_return(%{"></a>whatever<a title="})
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{milestone.reference_link_text} in #{another_project.path}"
    end
  end

  shared_examples 'cross project shorthand reference' do
    let(:namespace)       { create(:namespace) }
    let(:project)         { create(:project, :public, namespace: namespace) }
    let(:another_project) { create(:project, :public, namespace: namespace) }
    let(:milestone)       { create(:milestone, project: another_project) }
    let(:reference)       { "#{another_project.path}%#{milestone.iid}" }
    let!(:result)         { reference_filter("See #{reference}") }

    it 'points to referenced project milestone page' do
      expect(result.css('a').first.attr('href')).to eq urls
        .project_milestone_url(another_project, milestone)
    end

    it 'link has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.css('a').first.text)
        .to eq("#{milestone.reference_link_text} in #{another_project.path}")
    end

    it 'has valid text' do
      doc = reference_filter("See (#{reference}.)")

      expect(doc.text)
        .to eq("See (#{milestone.reference_link_text} in #{another_project.path}.)")
    end

    it 'escapes the name attribute' do
      allow_next_instance_of(Milestone) do |instance|
        allow(instance).to receive(:title).and_return(%{"></a>whatever<a title="})
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{milestone.reference_link_text} in #{another_project.path}"
    end
  end

  shared_examples 'references with HTML entities' do
    before do
      milestone.update!(title: '&lt;html&gt;')
    end

    it 'links to a valid reference' do
      doc = reference_filter('See %"&lt;html&gt;"')

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
      expect(doc.text).to eq 'See %<html>'
    end

    it 'ignores invalid milestone names and escapes entities' do
      act = %(Milestone %"&lt;non valid&gt;")

      expect(reference_filter(act).to_html).to eq act
    end
  end

  shared_context 'project milestones' do
    let(:reference) { milestone.to_reference(format: :iid) }

    include_examples 'reference parsing'

    it_behaves_like 'Integer-based references'
    it_behaves_like 'String-based single-word references'
    it_behaves_like 'String-based multi-word references in quotes'
    it_behaves_like 'referencing a milestone in a link href'
    it_behaves_like 'cross-project / cross-namespace complete reference'
    it_behaves_like 'cross-project / same-namespace complete reference'
    it_behaves_like 'cross project shorthand reference'
    it_behaves_like 'references with HTML entities'
    it_behaves_like 'HTML text with references' do
      let(:resource) { milestone }
      let(:resource_text) { "#{resource.class.reference_prefix}#{resource.title}" }
    end
  end

  shared_context 'group milestones' do
    let(:reference) { milestone.to_reference(format: :name) }

    include_examples 'reference parsing'

    it_behaves_like 'String-based single-word references'
    it_behaves_like 'String-based multi-word references in quotes'
    it_behaves_like 'referencing a milestone in a link href'
    it_behaves_like 'references with HTML entities'
    it_behaves_like 'HTML text with references' do
      let(:resource) { milestone }
      let(:resource_text) { "#{resource.class.reference_prefix}#{resource.title}" }
    end

    it 'does not support references by IID' do
      doc = reference_filter("See #{Milestone.reference_prefix}#{milestone.iid}")

      expect(doc.css('a')).to be_empty
    end

    it 'does not support references by link' do
      doc = reference_filter("See #{urls.milestone_url(milestone)}")

      expect(doc.css('a').first.text).to eq(urls.milestone_url(milestone))
    end

    it 'does not support cross-project references' do
      another_group = create(:group)
      another_project = create(:project, :public, group: group)
      project_reference = another_project.to_reference(project)

      milestone.update!(group: another_group)

      doc = reference_filter("See #{project_reference}#{reference}")

      expect(doc.css('a')).to be_empty
    end

    it 'supports parent group references' do
      milestone.update!(group: parent_group)

      doc = reference_filter("See #{reference}")
      expect(doc.css('a').first.text).to eq(milestone.reference_link_text)
    end
  end

  context 'group context' do
    let(:group) { create(:group) }
    let(:context) { { project: nil, group: group } }

    context 'when project milestone' do
      let(:milestone) { create(:milestone, project: project) }

      it 'links to a valid reference' do
        reference = "#{project.full_path}%#{milestone.iid}"

        result = reference_filter("See #{reference}", context)

        expect(result.css('a').first.attr('href')).to eq(urls.milestone_url(milestone))
      end

      it 'ignores internal references' do
        exp = act = "See %#{milestone.iid}"

        expect(reference_filter(act, context).to_html).to eq exp
      end
    end

    context 'when group milestone' do
      let(:group_milestone) { create(:milestone, title: 'group_milestone', group: group) }

      context 'for subgroups' do
        let(:sub_group) { create(:group, parent: group) }
        let(:sub_group_milestone) { create(:milestone, title: 'sub_group_milestone', group: sub_group) }

        it 'links to a valid reference of subgroup and group milestones' do
          [group_milestone, sub_group_milestone].each do |milestone|
            reference = "%#{milestone.title}"

            result = reference_filter("See #{reference}", { project: nil, group: sub_group })

            expect(result.css('a').first.attr('href')).to eq(urls.milestone_url(milestone))
          end
        end
      end

      it 'ignores internal references' do
        exp = act = "See %#{group_milestone.iid}"

        expect(reference_filter(act, context).to_html).to eq exp
      end
    end
  end

  context 'when milestone is open' do
    context 'project milestones' do
      let(:milestone) { create(:milestone, project: project) }

      include_context 'project milestones'
    end

    context 'group milestones' do
      let(:milestone) { create(:milestone, group: group) }

      include_context 'group milestones'
    end
  end

  context 'when milestone is closed' do
    context 'project milestones' do
      let(:milestone) { create(:milestone, :closed, project: project) }

      include_context 'project milestones'
    end

    context 'group milestones' do
      let(:milestone) { create(:milestone, :closed, group: group) }

      include_context 'group milestones'
    end
  end
end

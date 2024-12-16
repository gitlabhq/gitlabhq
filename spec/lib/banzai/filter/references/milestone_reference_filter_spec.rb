# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::MilestoneReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:parent_group) { create(:group, :public) }
  let_it_be(:group) { create(:group, :public, parent: parent_group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:another_project) { create(:project, :public, namespace: namespace) }

  it 'requires project context' do
    expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
  end

  shared_examples 'reference parsing' do
    %w[pre code a style].each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        act = "<#{elem}>milestone #{reference}</#{elem}>"
        expect(reference_filter(act).to_html).to include act
      end
    end

    it 'includes default classes' do
      doc = reference_filter("Milestone #{reference}")

      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-milestone has-tooltip'
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{reference}")
      link = doc.css('a').first

      if milestone.project.present?
        expect(link).to have_attribute('data-project')
        expect(link.attr('data-project')).to eq project.id.to_s
      elsif milestone.group.present?
        expect(link).to have_attribute('data-group')
        expect(link.attr('data-group')).to eq milestone.group.id.to_s
      end
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

      expect(link).not_to match %r{https?://}
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
      expect(doc.to_html).to match(%r{\(<a.+>#{milestone.reference_link_text}</a>\.\)})
    end

    it 'ignores invalid milestone IIDs' do
      act = "Milestone #{invalidate_reference(reference)}"

      expect(reference_filter(act).to_html).to include act
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
      expect(doc.to_html).to match(%r{\(<a.+>#{milestone.reference_link_text}</a>\.\)})
    end

    it 'links with adjacent html tags' do
      doc = reference_filter("Milestone <p>#{reference}</p>.")
      expect(doc.to_html).to match(%r{<p><a.+>#{milestone.reference_link_text}</a></p>})
    end

    it 'ignores invalid milestone names' do
      act = "Milestone #{Milestone.reference_prefix}#{milestone.name.reverse}"

      expect(reference_filter(act).to_html).to include act
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
      expect(doc.to_html).to match(%r{\(<a.+>#{milestone.reference_link_text}</a>\.\)})
    end

    it 'ignores invalid milestone names' do
      act = %(Milestone #{Milestone.reference_prefix}"#{milestone.name.reverse}")

      expect(reference_filter(act).to_html).to include act
    end
  end

  shared_examples 'referencing a milestone in a link href' do
    let(:unquoted_reference) { "#{Milestone.reference_prefix}#{milestone.name}" }
    let(:link_reference) { %(<a href="#{unquoted_reference}">Milestone</a>) }

    before do
      milestone.update!(name: 'gfm')
    end

    it 'links to a valid reference' do
      doc = reference_filter("See #{link_reference}")

      expect(doc.css('a').first.attr('href')).to eq urls.milestone_url(milestone)
    end

    it 'links with adjacent text' do
      doc = reference_filter("Milestone (#{link_reference}.)")
      expect(doc.to_html).to match(%r{\(<a.+>Milestone</a>\.\)})
    end

    it 'includes a data-project attribute' do
      doc = reference_filter("Milestone #{link_reference}")
      link = doc.css('a').first

      if milestone.project.present?
        expect(link).to have_attribute('data-project')
        expect(link.attr('data-project')).to eq project.id.to_s
      elsif milestone.group.present?
        expect(link).to have_attribute('data-group')
        expect(link.attr('data-group')).to eq milestone.group.id.to_s
      end
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
    let(:link_reference) { %(<a href="#{link}">#{link}</a>) }

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
    let_it_be(:milestone) { create(:milestone, project: another_project) }
    let(:reference) { "#{another_project.full_path}%#{milestone.iid}" }
    let!(:result) { reference_filter("See #{reference}") }

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
        allow(instance).to receive(:title).and_return(%("></a>whatever<a title="))
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{milestone.reference_link_text} in #{another_project.full_path}"
    end
  end

  shared_examples 'cross-project / same-namespace complete reference' do
    let_it_be(:project) { create(:project, :public, namespace: namespace) }
    let_it_be(:milestone) { create(:milestone, project: another_project) }
    let(:reference) { "#{another_project.full_path}%#{milestone.iid}" }
    let!(:result) { reference_filter("See #{reference}") }

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
        allow(instance).to receive(:title).and_return(%("></a>whatever<a title="))
      end

      doc = reference_filter("See #{reference}")

      expect(doc.css('a').first.text)
        .to eq "#{milestone.reference_link_text} in #{another_project.path}"
    end
  end

  shared_examples 'cross project shorthand reference' do
    let_it_be(:project) { create(:project, :public, namespace: namespace) }
    let_it_be(:milestone) { create(:milestone, project: another_project) }
    let(:reference) { "#{another_project.path}%#{milestone.iid}" }
    let!(:result) { reference_filter("See #{reference}") }

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
        allow(instance).to receive(:title).and_return(%("></a>whatever<a title="))
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

      expect(reference_filter(act).to_html).to include act
    end
  end

  shared_examples 'absolute references' do
    it 'supports absolute reference' do
      absolute_reference = "/#{reference}"

      result = reference_filter("See #{absolute_reference}")

      expect(result.css('a').first.attr('href')).to eq(urls.milestone_url(milestone))
      expect(result.css('a').first.attr('data-original')).to eq absolute_reference
      expect(result.content).to eq "See %#{milestone.title}"
    end
  end

  shared_context 'project milestones' do
    let(:reference) { milestone.to_reference(format: :iid) }

    include_examples 'reference parsing'

    it_behaves_like 'Integer-based references'
    it_behaves_like 'String-based single-word references'
    it_behaves_like 'String-based multi-word references in quotes'
    it_behaves_like 'referencing a milestone in a link href'
    it_behaves_like 'linking to a milestone as the entire link'
    it_behaves_like 'cross-project / cross-namespace complete reference'
    it_behaves_like 'cross-project / same-namespace complete reference'
    it_behaves_like 'cross project shorthand reference'
    it_behaves_like 'references with HTML entities'
    it_behaves_like 'HTML text with references' do
      let(:resource) { milestone }
      let(:resource_text) { "#{resource.class.reference_prefix}#{resource.title}" }
    end

    it_behaves_like 'absolute references' do
      let(:reference) { milestone.to_reference(format: :iid, full: true) }
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

    it_behaves_like 'absolute references' do
      let(:reference) { milestone.to_reference(format: :name, full: true) }
    end

    it 'does not support references by IID' do
      doc = reference_filter("See #{Milestone.reference_prefix}#{milestone.iid}")

      expect(doc.css('a')).to be_empty
    end

    it 'does not support references by link' do
      doc = reference_filter("See #{urls.milestone_url(milestone)}")

      expect(doc.css('a').first.text).to eq(urls.milestone_url(milestone))
    end

    it 'does not support cross-project references', :aggregate_failures do
      another_group = create(:group)
      another_project = create(:project, :public, group: group)
      project_reference = another_project.to_reference_base(project)
      input_text = "See #{project_reference}#{reference}"

      milestone.update!(group: another_group)

      doc = reference_filter(input_text)

      expect(input_text).to match(Milestone.reference_pattern)
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
        act = "See %#{milestone.iid}"

        expect(reference_filter(act, context).to_html).to include act
      end

      it_behaves_like 'absolute references' do
        let(:reference) { "#{project.full_path}%#{milestone.iid}" }
      end
    end

    context 'when group milestone' do
      let(:group_milestone) { create(:milestone, title: 'group_milestone', group: group) }

      context 'for subgroups' do
        let(:sub_group) { create(:group, parent: group) }
        let(:sub_group_milestone) { create(:milestone, title: 'sub_group_milestone', group: sub_group) }

        it 'links to valid references of subgroup and group milestones' do
          [group_milestone, sub_group_milestone].each do |milestone|
            reference = "%#{milestone.title}"

            result = reference_filter("See #{reference}", { project: nil, group: sub_group })

            expect(result.css('a').first.attr('href')).to eq(urls.milestone_url(milestone))
          end
        end

        it 'links to valid absolute references of subgroup and group milestones' do
          [group_milestone, sub_group_milestone].each do |milestone|
            reference = "/#{milestone.group.full_path}%#{milestone.title}"

            result = reference_filter("See #{reference}", { project: nil, group: sub_group })

            expect(result.css('a').first.attr('href')).to eq(urls.milestone_url(milestone))
            expect(result.css('a').first.attr('data-original')).to eq reference
            expect(result.content).to eq "See %#{milestone.title}"
          end
        end
      end

      it 'ignores internal references' do
        act = "See %#{group_milestone.iid}"

        expect(reference_filter(act, context).to_html).to include act
      end
    end

    context 'when referencing both project and group milestones' do
      let(:milestone) { create(:milestone, project: project) }
      let(:group_milestone) { create(:milestone, title: 'group_milestone', group: group) }

      it 'links to valid references' do
        links = reference_filter("See #{milestone.to_reference(full: true)} and #{group_milestone.to_reference}", context).css('a')

        expect(links.length).to eq(2)
        expect(links[0].attr('href')).to eq(urls.milestone_url(milestone))
        expect(links[1].attr('href')).to eq(urls.milestone_url(group_milestone))
      end
    end

    context 'when referencing both project and group milestones using absolute references' do
      let(:milestone) { create(:milestone, project: project) }
      let(:group_milestone) { create(:milestone, title: 'group_milestone', group: project.group) }

      it 'links to valid references' do
        doc = reference_filter("See /#{milestone.to_reference(full: true)} and /#{group_milestone.to_reference(full: true)}", context)
        links = doc.css('a')

        expect(links.length).to eq(2)
        expect(links[0].attr('href')).to eq(urls.milestone_url(milestone))
        expect(links[1].attr('href')).to eq(urls.milestone_url(group_milestone))
      end
    end

    context 'when referencing both group and subgroup milestones using absolute references' do
      let(:subgroup) { create(:group, :public, parent: group) }
      let(:group_milestone) { create(:milestone, title: 'group_milestone', group: group) }
      let(:subgroup_milestone) { create(:milestone, title: 'subgroup_milestone', group: subgroup) }
      let(:context) { { project: project, group: nil } }

      it 'links to valid references' do
        doc = reference_filter("See /#{group_milestone.to_reference(full: true)} and /#{subgroup_milestone.to_reference(full: true)}", context)
        links = doc.css('a')

        expect(links.length).to eq(2)
        expect(links[0].attr('href')).to eq(urls.milestone_url(group_milestone))
        expect(links[1].attr('href')).to eq(urls.milestone_url(subgroup_milestone))
      end
    end
  end

  context 'when milestone is open' do
    context 'project milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, project: project) }

      include_context 'project milestones'
    end

    context 'group milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, group: group) }

      include_context 'group milestones'
    end
  end

  context 'when milestone is closed' do
    context 'project milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, :closed, project: project) }

      include_context 'project milestones'
    end

    context 'group milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, :closed, group: group) }

      include_context 'group milestones'
    end
  end

  context 'checking N+1' do
    let_it_be(:group)              { create(:group) }
    let_it_be(:group2)             { create(:group) }
    let_it_be(:project)            { create(:project, :public, namespace: group) }
    let_it_be(:project2)           { create(:project, :public, namespace: group2) }
    let_it_be(:project3)           { create(:project, :public) }
    let_it_be(:project_milestone)  { create(:milestone, project: project) }
    let_it_be(:project_milestone2) { create(:milestone, project: project) }
    let_it_be(:project2_milestone) { create(:milestone, project: project2) }
    let_it_be(:group2_milestone)   { create(:milestone, group: group2) }
    let_it_be(:project_reference)  { project_milestone.to_reference.to_s }
    let_it_be(:project_reference2) { project_milestone2.to_reference.to_s }
    let_it_be(:project2_reference) { project2_milestone.to_reference(full: true).to_s }
    let_it_be(:group2_reference)   { "#{project2.full_path}%\"#{group2_milestone.name}\"" }

    it 'does not have N+1 per multiple references per project', :use_sql_query_cache do
      markdown = project_reference.to_s
      control_count = 4

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)

      markdown = "#{project_reference} %qwert %werty %ertyu %rtyui #{project_reference2}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)
    end

    it 'has N+1 for multiple unique project/group references', :use_sql_query_cache do
      markdown = project_reference.to_s
      control_count = 4

      expect do
        reference_filter(markdown, project: project)
      end.not_to exceed_all_query_limit(control_count)

      # Since we're not batching milestone queries across projects/groups,
      # queries increase when a new project/group is added.
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      markdown = "#{project_reference} #{group2_reference}"
      control_count += 9

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)

      # third reference to already queried project/namespace, nothing extra (no N+1 here)
      markdown = "#{project_reference} #{group2_reference} #{project_reference2}"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)

      # last reference needs additional queries
      markdown = "#{project_reference} #{group2_reference} #{project2_reference} #{project3.full_path}%test_milestone"
      control_count += 6

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)

      # Use an iid instead of title reference
      markdown = "#{project_reference} #{group2_reference} #{project2.full_path}%#{project2_milestone.iid} #{project3.full_path}%test_milestone"

      expect do
        reference_filter(markdown)
      end.not_to exceed_all_query_limit(control_count)
    end
  end
end

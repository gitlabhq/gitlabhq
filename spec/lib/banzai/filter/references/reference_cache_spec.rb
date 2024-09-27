# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::ReferenceCache, feature_category: :markdown do
  let_it_be(:group)    { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project)  { create(:project, group: group) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:issue1)   { create(:issue, project: project) }
  let_it_be(:issue2)   { create(:issue, project: project) }
  let_it_be(:issue3)   { create(:issue, project: project2) }
  let_it_be(:issue4)   { create(:issue, project: project2) }
  let_it_be(:doc)      { Nokogiri::HTML.fragment("#{issue1.to_reference} #{issue2.to_reference} #{issue3.to_reference(full: true)}") }
  let_it_be(:result)   { {} }
  let_it_be(:filter_class) { Banzai::Filter::References::IssueReferenceFilter }

  let(:filter) { filter_class.new(doc, project: project) }
  let(:cache)  { described_class.new(filter, { project: project }, result) }

  describe '#load_reference_cache' do
    subject { cache.load_reference_cache(filter.nodes) }

    context 'when rendered_html is not memoized' do
      it 'generates new html' do
        expect(doc).to receive(:to_html).and_call_original

        subject
      end
    end

    context 'when rendered_html is memoized' do
      let(:result) { { rendered_html: 'html' } }

      it 'reuses memoized rendered HTML when available' do
        expect(doc).not_to receive(:to_html)

        subject
      end
    end

    context 'when result is not available' do
      let(:result) { nil }

      it { expect { subject }.not_to raise_error }
    end

    context 'when cache is loaded' do
      let_it_be(:cache) do
        filter = filter_class.new(doc, project: project)
        cache = described_class.new(filter, { project: project }, result)
        cache.load_reference_cache(filter.nodes)
        cache
      end

      it 'loads the cache' do
        expect(cache.cache_loaded?).to be_truthy
      end

      describe '#references_per_parent' do
        it 'loads references grouped per parent paths' do
          expect(cache.references_per_parent).to eq({ project.full_path => [issue1.iid, issue2.iid].to_set,
                                                      project2.full_path => [issue3.iid].to_set })
        end
      end

      describe '#parent_per_reference' do
        it 'returns a Hash containing projects grouped per parent paths' do
          expect(cache.parent_per_reference).to include({ project.full_path => project, project2.full_path => project2 })
        end
      end

      describe '#records_per_parent' do
        it 'returns a Hash containing records grouped per parent' do
          expect(cache.records_per_parent).to match({ project => { issue1.iid => issue1, issue2.iid => issue2 },
                                                      project2 => { issue3.iid => issue3 } })
        end
      end
    end

    context 'when the cache is loaded with absolute references' do
      it 'loads references grouped per parent path and absolute references' do
        milestone1 = create(:milestone, group: group)
        milestone2 = create(:milestone, group: subgroup)
        milestone3 = create(:milestone, project: project)

        doc_milestone = Nokogiri::HTML.fragment("/#{milestone1.to_reference(full: true)} /#{milestone2.to_reference(full: true)} #{milestone3.to_reference(full: true)}")
        filter_milestone = Banzai::Filter::References::MilestoneReferenceFilter.new(doc_milestone, project: project)
        cache_milestone = described_class.new(filter_milestone, { project: project }, {})

        cache_milestone.load_reference_cache(filter_milestone.nodes)

        expect(cache_milestone.references_per_parent).to match({
          "/#{group.full_path}" => [{ milestone_iid: nil, milestone_name: milestone1.title, absolute_path: true }].to_set,
          "/#{subgroup.full_path}" => [{ milestone_iid: nil, milestone_name: milestone2.title, absolute_path: true }].to_set,
          project.full_path => [{ milestone_iid: nil, milestone_name: milestone3.title, absolute_path: false }].to_set
        })

        expect(cache_milestone.parent_per_reference).to match({
          "/#{group.full_path}" => group,
          "/#{subgroup.full_path}" => subgroup,
          project.full_path => project
        })

        expect(cache_milestone.records_per_parent).to match({
          group => { { milestone_iid: milestone1.iid, milestone_name: milestone1.title } => milestone1 },
          subgroup => { { milestone_iid: milestone2.iid, milestone_name: milestone2.title } => milestone2 },
          project => { { milestone_iid: milestone3.iid, milestone_name: milestone3.title } => milestone3 }
        })
      end
    end
  end

  describe '#initialize_reference_cache' do
    it 'does not have an N+1 query problem with cross projects' do
      doc_single = Nokogiri::HTML.fragment("#1")
      filter_single = filter_class.new(doc_single, project: project)
      cache_single = described_class.new(filter_single, { project: project }, {})

      control = ActiveRecord::QueryRecorder.new do
        cache_single.load_reference_cache(filter_single.nodes)
      end

      expect(control.count).to eq 3
      # Since this is an issue filter that is not batching issue queries
      # across projects, we have to account for that.
      # 1 for for routes to find routes.source_id of projects matching paths
      # 1 for projects belonging to the above routes
      # 1 for preloading routes of the projects
      # 1 for loading the namespaces associated to the project
      # 1 for loading the routes associated with the namespace
      # 1x2 for issues
      # 1x2 for groups
      # 1x2 for work_item_types
      # Total = 11
      expect do
        cache.load_reference_cache(filter.nodes)
      end.not_to exceed_query_limit(control).with_threshold(8)
    end
  end

  describe '#find_for_paths' do
    def find_for_paths(paths, absolute_path = false)
      cache.send(:find_for_paths, paths, absolute_path)
    end

    context 'with RequestStore disabled' do
      it 'returns a list of Projects for a list of paths' do
        expect(find_for_paths([project.full_path])).to eq([project])
      end

      it 'return an empty array for paths that do not exist' do
        expect(find_for_paths(['nonexistent/project'])).to eq([])
      end

      it 'finds group and project by absolute path' do
        project_path = "/#{project.full_path}"
        group_path = "/#{subgroup.full_path}"
        nonexistent_path = '/nonexistent/project'

        expect(find_for_paths([project_path, group_path, nonexistent_path], true)).to match_array([project, subgroup])
      end
    end

    context 'with RequestStore enabled', :request_store do
      it 'returns a list of Projects for a list of paths' do
        expect(find_for_paths([project.full_path])).to eq([project])
      end

      context 'when no project with that path exists' do
        it 'returns no value' do
          expect(find_for_paths(['nonexistent/project'])).to eq([])
        end

        it 'adds the ref to the project refs cache' do
          project_refs_cache = {}
          allow(cache).to receive(:refs_cache).and_return(project_refs_cache)

          find_for_paths(['nonexistent/project'])

          expect(project_refs_cache).to eq({ 'nonexistent/project' => nil })
        end
      end
    end
  end

  describe '#current_parent_path' do
    it 'returns the path of the current parent' do
      cache.clear_memoization(:current_parent_path)

      expect(cache.current_parent_path).to eq project.full_path
    end
  end

  describe '#current_project_namespace_path' do
    it 'returns the path of the current project namespace' do
      cache.clear_memoization(:current_project_namespace_path)

      expect(cache.current_project_namespace_path).to eq project.namespace.full_path
    end
  end

  describe '#full_project_path' do
    it 'returns current parent path when no ref specified' do
      expect(cache.full_project_path('something', nil)).to eq cache.current_parent_path
    end

    it 'returns combined namespace and project ref' do
      expect(cache.full_project_path('something', 'cool')).to eq 'something/cool'
    end

    it 'returns default namespace and project ref when namespace nil' do
      expect(cache.full_project_path(nil, 'cool')).to eq "#{project.namespace.full_path}/cool"
    end

    it 'returns absolute paths when matched to an absolute path' do
      match = "/something/cool".match(Project.reference_pattern)

      expect(cache.full_project_path('something', 'cool', match)).to eq '/something/cool'
      expect(cache.full_project_path(nil, 'cool', match)).to eq '/cool'
    end
  end

  describe '#full_group_path' do
    it 'returns current parent path when no group ref specified' do
      expect(cache.full_group_path(nil)).to eq cache.current_parent_path
    end

    it 'returns group ref' do
      expect(cache.full_group_path('cool_group')).to eq 'cool_group'
    end
  end
end

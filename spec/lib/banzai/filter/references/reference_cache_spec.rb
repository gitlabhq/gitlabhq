# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::ReferenceCache do
  let_it_be(:project)  { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:issue1)   { create(:issue, project: project) }
  let_it_be(:issue2)   { create(:issue, project: project) }
  let_it_be(:issue3)   { create(:issue, project: project2) }
  let_it_be(:doc)      { Nokogiri::HTML.fragment("#{issue1.to_reference} #{issue2.to_reference} #{issue3.to_reference(full: true)}") }

  let(:filter_class) { Banzai::Filter::References::IssueReferenceFilter }
  let(:filter)       { filter_class.new(doc, project: project) }
  let(:cache)        { described_class.new(filter, { project: project }) }

  describe '#load_references_per_parent' do
    it 'loads references grouped per parent paths' do
      cache.load_references_per_parent(filter.nodes)

      expect(cache.references_per_parent).to eq({ project.full_path => [issue1.iid, issue2.iid].to_set,
                                                  project2.full_path => [issue3.iid].to_set })
    end
  end

  describe '#load_parent_per_reference' do
    it 'returns a Hash containing projects grouped per parent paths' do
      cache.load_references_per_parent(filter.nodes)
      cache.load_parent_per_reference

      expect(cache.parent_per_reference).to match({ project.full_path => project, project2.full_path => project2 })
    end
  end

  describe '#load_records_per_parent' do
    it 'returns a Hash containing projects grouped per parent paths' do
      cache.load_references_per_parent(filter.nodes)
      cache.load_parent_per_reference
      cache.load_records_per_parent

      expect(cache.records_per_parent).to match({ project => { issue1.iid => issue1, issue2.iid => issue2 },
                                                  project2 => { issue3.iid => issue3 } })
    end
  end

  describe '#initialize_reference_cache' do
    it 'does not have an N+1 query problem with cross projects' do
      doc_single = Nokogiri::HTML.fragment("#1")
      filter_single = filter_class.new(doc_single, project: project)
      cache_single = described_class.new(filter_single, { project: project })

      control_count = ActiveRecord::QueryRecorder.new do
        cache_single.load_references_per_parent(filter_single.nodes)
        cache_single.load_parent_per_reference
        cache_single.load_records_per_parent
      end.count

      expect(control_count).to eq 1

      # Since this is an issue filter that is not batching issue queries
      # across projects, we have to account for that.
      # 1 for original issue, 2 for second route/project, 1 for other issue
      max_count = control_count + 3

      expect do
        cache.load_references_per_parent(filter.nodes)
        cache.load_parent_per_reference
        cache.load_records_per_parent
      end.not_to exceed_query_limit(max_count)
    end
  end

  describe '#find_for_paths' do
    context 'with RequestStore disabled' do
      it 'returns a list of Projects for a list of paths' do
        expect(cache.find_for_paths([project.full_path]))
          .to eq([project])
      end

      it 'return an empty array for paths that do not exist' do
        expect(cache.find_for_paths(['nonexistent/project']))
          .to eq([])
      end
    end

    context 'with RequestStore enabled', :request_store do
      it 'returns a list of Projects for a list of paths' do
        expect(cache.find_for_paths([project.full_path]))
          .to eq([project])
      end

      context 'when no project with that path exists' do
        it 'returns no value' do
          expect(cache.find_for_paths(['nonexistent/project']))
            .to eq([])
        end

        it 'adds the ref to the project refs cache' do
          project_refs_cache = {}
          allow(cache).to receive(:refs_cache).and_return(project_refs_cache)

          cache.find_for_paths(['nonexistent/project'])

          expect(project_refs_cache).to eq({ 'nonexistent/project' => nil })
        end
      end
    end
  end

  describe '#current_parent_path' do
    it 'returns the path of the current parent' do
      expect(cache.current_parent_path).to eq project.full_path
    end
  end

  describe '#current_project_namespace_path' do
    it 'returns the path of the current project namespace' do
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

    it 'returns uses default namespace and project ref when namespace nil' do
      expect(cache.full_project_path(nil, 'cool')).to eq "#{project.namespace.full_path}/cool"
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

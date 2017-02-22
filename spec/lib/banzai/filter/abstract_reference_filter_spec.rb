require 'spec_helper'

describe Banzai::Filter::AbstractReferenceFilter do
  let(:project) { create(:empty_project) }

  describe '#references_per_project' do
    it 'returns a Hash containing references grouped per project paths' do
      doc = Nokogiri::HTML.fragment("#1 #{project.path_with_namespace}#2")
      filter = described_class.new(doc, project: project)

      expect(filter).to receive(:object_class).exactly(4).times.and_return(Issue)
      expect(filter).to receive(:object_sym).twice.and_return(:issue)

      refs = filter.references_per_project

      expect(refs).to be_an_instance_of(Hash)
      expect(refs[project.path_with_namespace]).to eq(Set.new(%w[1 2]))
    end
  end

  describe '#projects_per_reference' do
    it 'returns a Hash containing projects grouped per project paths' do
      doc = Nokogiri::HTML.fragment('')
      filter = described_class.new(doc, project: project)

      expect(filter).to receive(:references_per_project).
        and_return({ project.path_with_namespace => Set.new(%w[1]) })

      expect(filter.projects_per_reference).
        to eq({ project.path_with_namespace => project })
    end
  end

  describe '#find_projects_for_paths' do
    let(:doc) { Nokogiri::HTML.fragment('') }
    let(:filter) { described_class.new(doc, project: project) }

    context 'with RequestStore disabled' do
      it 'returns a list of Projects for a list of paths' do
        expect(filter.find_projects_for_paths([project.path_with_namespace])).
          to eq([project])
      end

      it "return an empty array for paths that don't exist" do
        expect(filter.find_projects_for_paths(['nonexistent/project'])).
          to eq([])
      end
    end

    context 'with RequestStore enabled' do
      before do
        RequestStore.begin!
      end

      after do
        RequestStore.end!
        RequestStore.clear!
      end

      it 'returns a list of Projects for a list of paths' do
        expect(filter.find_projects_for_paths([project.path_with_namespace])).
          to eq([project])
      end

      context "when no project with that path exists" do
        it "returns no value" do
          expect(filter.find_projects_for_paths(['nonexistent/project'])).
            to eq([])
        end

        it "adds the ref to the project refs cache" do
          project_refs_cache = {}
          allow(filter).to receive(:project_refs_cache).and_return(project_refs_cache)

          filter.find_projects_for_paths(['nonexistent/project'])

          expect(project_refs_cache).to eq({ 'nonexistent/project' => nil })
        end

        context 'when the project refs cache includes nil values' do
          before do
            # adds { 'nonexistent/project' => nil } to cache
            filter.project_from_ref_cached('nonexistent/project')
          end

          it "return an empty array for paths that don't exist" do
            expect(filter.find_projects_for_paths(['nonexistent/project'])).
              to eq([])
          end
        end
      end
    end
  end

  describe '#current_project_path' do
    it 'returns the path of the current project' do
      doc = Nokogiri::HTML.fragment('')
      filter = described_class.new(doc, project: project)

      expect(filter.current_project_path).to eq(project.path_with_namespace)
    end
  end
end

require 'spec_helper'

describe Banzai::Filter::AbstractReferenceFilter do
  let(:project) { create(:project) }

  describe '#references_per_parent' do
    it 'returns a Hash containing references grouped per parent paths' do
      doc = Nokogiri::HTML.fragment("#1 #{project.full_path}#2")
      filter = described_class.new(doc, project: project)

      expect(filter).to receive(:object_class).exactly(4).times.and_return(Issue)
      expect(filter).to receive(:object_sym).twice.and_return(:issue)

      refs = filter.references_per_parent

      expect(refs).to be_an_instance_of(Hash)
      expect(refs[project.full_path]).to eq(Set.new(%w[1 2]))
    end
  end

  describe '#parent_per_reference' do
    it 'returns a Hash containing projects grouped per parent paths' do
      doc = Nokogiri::HTML.fragment('')
      filter = described_class.new(doc, project: project)

      expect(filter).to receive(:references_per_parent)
        .and_return({ project.full_path => Set.new(%w[1]) })

      expect(filter.parent_per_reference)
        .to eq({ project.full_path => project })
    end
  end

  describe '#find_for_paths' do
    let(:doc) { Nokogiri::HTML.fragment('') }
    let(:filter) { described_class.new(doc, project: project) }

    context 'with RequestStore disabled' do
      it 'returns a list of Projects for a list of paths' do
        expect(filter.find_for_paths([project.full_path]))
          .to eq([project])
      end

      it "return an empty array for paths that don't exist" do
        expect(filter.find_for_paths(['nonexistent/project']))
          .to eq([])
      end
    end

    context 'with RequestStore enabled', :request_store do
      it 'returns a list of Projects for a list of paths' do
        expect(filter.find_for_paths([project.full_path]))
          .to eq([project])
      end

      context "when no project with that path exists" do
        it "returns no value" do
          expect(filter.find_for_paths(['nonexistent/project']))
            .to eq([])
        end

        it "adds the ref to the project refs cache" do
          project_refs_cache = {}
          allow(filter).to receive(:refs_cache).and_return(project_refs_cache)

          filter.find_for_paths(['nonexistent/project'])

          expect(project_refs_cache).to eq({ 'nonexistent/project' => nil })
        end

        context 'when the project refs cache includes nil values' do
          before do
            # adds { 'nonexistent/project' => nil } to cache
            filter.from_ref_cached('nonexistent/project')
          end

          it "return an empty array for paths that don't exist" do
            expect(filter.find_for_paths(['nonexistent/project']))
              .to eq([])
          end
        end
      end
    end
  end

  describe '#current_parent_path' do
    it 'returns the path of the current parent' do
      doc = Nokogiri::HTML.fragment('')
      filter = described_class.new(doc, project: project)

      expect(filter.current_parent_path).to eq(project.full_path)
    end
  end
end

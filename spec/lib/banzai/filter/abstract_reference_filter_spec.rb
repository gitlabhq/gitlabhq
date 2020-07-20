# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AbstractReferenceFilter do
  let_it_be(:project) { create(:project) }

  let(:doc) { Nokogiri::HTML.fragment('') }
  let(:filter) { described_class.new(doc, project: project) }

  describe '#references_per_parent' do
    let(:doc) { Nokogiri::HTML.fragment("#1 #{project.full_path}#2 #2") }

    it 'returns a Hash containing references grouped per parent paths' do
      expect(described_class).to receive(:object_class).exactly(6).times.and_return(Issue)

      refs = filter.references_per_parent

      expect(refs).to match(a_hash_including(project.full_path => contain_exactly(1, 2)))
    end
  end

  describe '#data_attributes_for' do
    let_it_be(:issue) { create(:issue, project: project) }

    it 'is not an XSS vector' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter.data_attributes_for('xss &lt;img onerror=alert(1) src=x&gt;', project, issue, link_content: true)

      expect(data_attributes[:original]).to eq('xss &amp;lt;img onerror=alert(1) src=x&amp;gt;')
    end
  end

  describe '#parent_per_reference' do
    it 'returns a Hash containing projects grouped per parent paths' do
      expect(filter).to receive(:references_per_parent)
        .and_return({ project.full_path => Set.new([1]) })

      expect(filter.parent_per_reference)
        .to eq({ project.full_path => project })
    end
  end

  describe '#find_for_paths' do
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

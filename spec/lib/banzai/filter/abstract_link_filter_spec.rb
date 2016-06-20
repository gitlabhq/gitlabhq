require 'spec_helper'

describe Banzai::Filter::AbstractReferenceFilter do
  let(:project) { create(:empty_project) }

  describe '#references_per_project' do
    it 'returns a Hash containing references grouped per project paths' do
      doc = Nokogiri::HTML.fragment("#1 #{project.to_reference}#2")
      filter = described_class.new(doc, project: project)

      expect(filter).to receive(:object_class).exactly(4).times.and_return(Issue)
      expect(filter).to receive(:object_sym).twice.and_return(:issue)

      refs = filter.references_per_project

      expect(refs).to be_an_instance_of(Hash)
      expect(refs[project.to_reference]).to eq(Set.new(%w[1 2]))
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
    it 'returns a list of Projects for a list of paths' do
      doc = Nokogiri::HTML.fragment('')
      filter = described_class.new(doc, project: project)

      expect(filter.find_projects_for_paths([project.path_with_namespace])).
        to eq([project])
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

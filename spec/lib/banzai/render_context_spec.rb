# frozen_string_literal: true

require 'spec_helper'

describe Banzai::RenderContext do
  let(:document) { Nokogiri::HTML.fragment('<p>hello</p>') }

  describe '#project_for_node' do
    it 'returns the default project if no associated project was found' do
      project = instance_double('project')
      context = described_class.new(project)

      expect(context.project_for_node(document)).to eq(project)
    end

    it 'returns the associated project if one was associated explicitly' do
      project = instance_double('project')
      obj = instance_double('object', project: project)
      context = described_class.new

      context.associate_document(document, obj)

      expect(context.project_for_node(document)).to eq(project)
    end

    it 'returns the project associated with a DocumentFragment when using a node' do
      project = instance_double('project')
      obj = instance_double('object', project: project)
      context = described_class.new
      node = document.children.first

      context.associate_document(document, obj)

      expect(context.project_for_node(node)).to eq(project)
    end
  end
end

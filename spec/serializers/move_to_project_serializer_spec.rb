# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MoveToProjectSerializer do
  describe '#represent' do
    it 'includes the name and name with namespace' do
      project = build(:project, id: 1)
      output = described_class.new.represent(project)

      expect(output).to include(:id, :name_with_namespace)
    end
  end
end

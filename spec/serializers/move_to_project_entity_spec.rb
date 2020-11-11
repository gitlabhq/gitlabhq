# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MoveToProjectEntity do
  describe '#as_json' do
    let(:project) { build(:project, id: 1) }

    subject { described_class.new(project).as_json }

    it 'includes the project ID' do
      expect(subject[:id]).to eq(project.id)
    end

    it 'includes the human-readable full path' do
      expect(subject[:name_with_namespace]).to eq(project.name_with_namespace)
    end

    it 'includes the full path' do
      expect(subject[:full_path]).to eq(project.full_path)
    end
  end
end

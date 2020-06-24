# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::BaseService do
  let(:noteable) { double }
  let(:project) { double }
  let(:author) { double }

  let(:base_service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#noteable' do
    subject { base_service.noteable }

    it { is_expected.to eq(noteable) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.noteable).to be_nil
    end
  end

  describe '#project' do
    subject { base_service.project }

    it { is_expected.to eq(project) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.project).to be_nil
    end
  end

  describe '#author' do
    subject { base_service.author }

    it { is_expected.to eq(author) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.author).to be_nil
    end
  end
end

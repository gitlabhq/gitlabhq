# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::BaseService, feature_category: :groups_and_projects do
  let(:noteable) { double }
  let(:project) { build(:project) }
  let(:author) { double }
  let(:container) { project }
  let(:base_service) { described_class.new(noteable: noteable, container: container, author: author) }

  describe '#noteable' do
    subject { base_service.noteable }

    it { is_expected.to eq(noteable) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.noteable).to be_nil
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

  describe '#container' do
    using RSpec::Parameterized::TableSyntax

    let(:project) { build(:project) }
    let(:project_namespace) { build(:project_namespace, project: project) }
    let(:group) { build(:group) }
    let(:user_namespace) { build(:user_namespace) }

    where(:container, :expected_container, :expected_project, :expected_group) do
      nil                     | nil                     | nil           | nil
      ref(:project)           | ref(:project)           | ref(:project) | nil
      ref(:project_namespace) | ref(:project_namespace) | ref(:project) | nil
      ref(:group)             | ref(:group)             | nil           | ref(:group)
      ref(:user_namespace)    | ref(:user_namespace)    | nil           | nil
    end

    with_them do
      it 'expects correct container type' do
        expect(base_service.container).to eq(expected_container)
        expect(base_service.project).to eq(expected_project)
        expect(base_service.group).to eq(expected_group)
      end
    end
  end
end

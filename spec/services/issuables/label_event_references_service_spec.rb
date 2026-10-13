# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::LabelEventReferencesService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_label) { create(:label, project: project) }
  let_it_be(:group_label) { create(:group_label, group: group) }
  let_it_be(:foreign_label) { create(:label) }
  let_it_be(:foreign_group_label) { create(:group_label) }

  let(:labels) { [project_label, group_label, foreign_label, foreign_group_label] }

  subject(:references) { described_class.new(parent).execute(labels) }

  context 'when the parent is a project' do
    let(:parent) { project }

    it 'returns a bare reference for reachable labels and a qualified one otherwise' do
      expect(references).to eq(
        project_label.id => "~#{project_label.id}",
        group_label.id => "~#{group_label.id}",
        foreign_label.id => "#{foreign_label.project.full_path}~#{foreign_label.id}",
        foreign_group_label.id => "#{foreign_group_label.group.full_path}~#{foreign_group_label.id}"
      )
    end

    it 'does not query per label for labels outside the parent' do
      control_labels = Label.id_in([create(:label), create(:group_label)].map(&:id)).to_a
      control = ActiveRecord::QueryRecorder.new { described_class.new(parent).execute(control_labels) }

      labels = Label.id_in((create_list(:label, 3) + create_list(:group_label, 3)).map(&:id)).to_a

      expect { described_class.new(parent).execute(labels) }.not_to exceed_query_limit(control)
    end
  end

  context 'when the parent is a group' do
    let(:parent) { group }

    it 'qualifies a label owned by a child project' do
      expect(references).to eq(
        project_label.id => "#{project.path}~#{project_label.id}",
        group_label.id => "~#{group_label.id}",
        foreign_label.id => "#{foreign_label.project.full_path}~#{foreign_label.id}",
        foreign_group_label.id => "#{foreign_group_label.group.full_path}~#{foreign_group_label.id}"
      )
    end
  end

  context 'when there is no parent' do
    let(:parent) { nil }

    it 'returns a bare reference for every label without looking up reachable labels' do
      expect(LabelsFinder).not_to receive(:new)

      expect(references).to eq(labels.to_h { |label| [label.id, "~#{label.id}"] })
    end
  end

  context 'when there are no labels' do
    let(:parent) { project }
    let(:labels) { [] }

    it 'returns no references without looking up reachable labels' do
      expect(LabelsFinder).not_to receive(:new)

      expect(references).to eq({})
    end
  end
end

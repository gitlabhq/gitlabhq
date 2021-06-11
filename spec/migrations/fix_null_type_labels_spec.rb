# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixNullTypeLabels do
  let(:migration) { described_class.new }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:labels) { table(:labels) }

  before do
    group = namespaces.create!(name: 'labels-test-project', path: 'labels-test-project', type: 'Group')
    project = projects.create!(namespace_id: group.id, name: 'labels-test-group', path: 'labels-test-group')

    @template_label = labels.create!(title: 'template', template: true)
    @project_label = labels.create!(title: 'project label', project_id: project.id, type: 'ProjectLabel')
    @group_label = labels.create!(title: 'group_label', group_id: group.id, type: 'GroupLabel')
    @broken_label_1 = labels.create!(title: 'broken 1', project_id: project.id)
    @broken_label_2 = labels.create!(title: 'broken 2', project_id: project.id)
  end

  describe '#up' do
    it 'fix labels with type missing' do
      migration.up

      # Labels that requires type change
      expect(@broken_label_1.reload.type).to eq('ProjectLabel')
      expect(@broken_label_2.reload.type).to eq('ProjectLabel')
      # Labels out of scope
      expect(@template_label.reload.type).to be_nil
      expect(@project_label.reload.type).to eq('ProjectLabel')
      expect(@group_label.reload.type).to eq('GroupLabel')
    end
  end
end

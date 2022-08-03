# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectNamespace, type: :model do
  describe 'relationships' do
    it { is_expected.to have_one(:project).with_foreign_key(:project_namespace_id).inverse_of(:project_namespace) }

    specify do
      project = create(:project)
      namespace = project.project_namespace
      namespace.reload_project

      expect(namespace.project).to eq project
    end
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of :owner }
  end

  context 'when deleting project namespace' do
    # using delete rather than destroy due to `delete` skipping AR hooks/callbacks
    # so it's ensured to work at the DB level. Uses ON DELETE CASCADE on foreign key
    let_it_be(:project) { create(:project) }
    let_it_be(:project_namespace) { project.project_namespace }

    it 'also deletes associated project' do
      project_namespace.delete

      expect { project_namespace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180906051323_remove_orphaned_label_links.rb')

describe RemoveOrphanedLabelLinks, :migration do
  let(:label_links) { table(:label_links) }
  let(:labels) { table(:labels) }

  let(:project) { create(:project) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:label) { create_label }

  before do
    # This migration was created before we introduced ProjectCiCdSetting#default_git_depth
    allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth).and_return(nil)
    allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth=).and_return(0)
  end

  context 'add foreign key on label_id' do
    let!(:label_link_with_label) { create_label_link(label_id: label.id) }
    let!(:label_link_without_label) { create_label_link(label_id: nil) }

    it 'removes orphaned labels without corresponding label' do
      expect { migrate! }.to change { LabelLink.count }.from(2).to(1)
    end

    it 'does not remove entries with valid label_id' do
      expect { migrate! }.not_to change { label_link_with_label.reload }
    end
  end

  def create_label(**opts)
    labels.create!(
      project_id: project.id,
      **opts
    )
  end

  def create_label_link(**opts)
    label_links.create!(
      target_id: 1,
      target_type: 'Issue',
      **opts
    )
  end
end

# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181219130552_update_project_import_visibility_level.rb')

describe UpdateProjectImportVisibilityLevel, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project) { projects.find_by_name(name) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  context 'private visibility level' do
    let(:name) { 'private-public' }

    it 'updates the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PRIVATE)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { migrate! }.to change { project.reload.visibility_level }.to(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  context 'internal visibility level' do
    let(:name) { 'internal-public' }

    it 'updates the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::INTERNAL)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { migrate! }.to change { project.reload.visibility_level }.to(Gitlab::VisibilityLevel::INTERNAL)
    end
  end

  context 'public visibility level' do
    let(:name) { 'public-public' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PUBLIC)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { migrate! }.not_to change { project.reload.visibility_level }
    end
  end

  context 'private project visibility level' do
    let(:name) { 'public-private' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PUBLIC)
      create_project(name, Gitlab::VisibilityLevel::PRIVATE)

      expect { migrate! }.not_to change { project.reload.visibility_level }
    end
  end

  context 'no namespace' do
    let(:name) { 'no-namespace' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PRIVATE, type: nil)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { migrate! }.not_to change { project.reload.visibility_level }
    end
  end

  def create_namespace(name, visibility, options = {})
    namespaces.create({
                        name: name,
                        path: name,
                        type: 'Group',
                        visibility_level: visibility
                      }.merge(options))
  end

  def create_project(name, visibility)
    projects.create!(namespace_id: namespaces.find_by_name(name).id,
                     name: name,
                     path: name,
                     import_type: 'gitlab_project',
                     visibility_level: visibility)
  end
end

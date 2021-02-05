# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddHasExternalIssueTrackerTrigger do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }

  before do
    @namespace = namespaces.create!(name: 'foo', path: 'foo')
    @project = projects.create!(namespace_id: @namespace.id)
  end

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger' do
      it 'sets `has_external_issue_tracker` to true when active `issue_tracker` is inserted' do
        expect do
          services.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        end.to change { @project.reload.has_external_issue_tracker }.to(true)
      end

      it 'does not set `has_external_issue_tracker` to true when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)

        expect do
          services.create!(category: 'issue_tracker', active: true, project_id: different_project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not set `has_external_issue_tracker` to true when inactive `issue_tracker` is inserted' do
        expect do
          services.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not set `has_external_issue_tracker` to true when a non-`issue tracker` active service is inserted' do
        expect do
          services.create!(category: 'my_type', active: true, project_id: @project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end

    describe 'UPDATE trigger' do
      it 'sets `has_external_issue_tracker` to true when `issue_tracker` is made active' do
        service = services.create!(category: 'issue_tracker', active: false, project_id: @project.id)

        expect do
          service.update!(active: true)
        end.to change { @project.reload.has_external_issue_tracker }.to(true)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is made inactive' do
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.update!(active: false)
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is made inactive, and an inactive `issue_tracker` exists' do
        services.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.update!(active: false)
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'does not change `has_external_issue_tracker` when `issue_tracker` is made inactive, if an active `issue_tracker` exists' do
        services.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.update!(active: false)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not change `has_external_issue_tracker` when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = services.create!(category: 'issue_tracker', active: false, project_id: different_project.id)

        expect do
          service.update!(active: true)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end

    describe 'DELETE trigger' do
      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is deleted' do
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.delete
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is deleted, if an inactive `issue_tracker` still exists' do
        services.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.delete
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'does not change `has_external_issue_tracker` when `issue_tracker` is deleted, if an active `issue_tracker` still exists' do
        services.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          service.delete
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not change `has_external_issue_tracker` when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = services.create!(category: 'issue_tracker', active: true, project_id: different_project.id)

        expect do
          service.delete
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    it 'drops the INSERT trigger' do
      expect do
        services.create!(category: 'issue_tracker', active: true, project_id: @project.id)
      end.not_to change { @project.reload.has_external_issue_tracker }
    end

    it 'drops the UPDATE trigger' do
      service = services.create!(category: 'issue_tracker', active: false, project_id: @project.id)
      @project.update!(has_external_issue_tracker: false)

      expect do
        service.update!(active: true)
      end.not_to change { @project.reload.has_external_issue_tracker }
    end

    it 'drops the DELETE trigger' do
      service = services.create!(category: 'issue_tracker', active: true, project_id: @project.id)
      @project.update!(has_external_issue_tracker: true)

      expect do
        service.delete
      end.not_to change { @project.reload.has_external_issue_tracker }
    end
  end
end

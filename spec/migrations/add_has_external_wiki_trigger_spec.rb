# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddHasExternalWikiTrigger do
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
      it 'sets `has_external_wiki` to true when active `ExternalWikiService` is inserted' do
        expect do
          services.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)
        end.to change { @project.reload.has_external_wiki }.to(true)
      end

      it 'does not set `has_external_wiki` to true when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)

        expect do
          services.create!(type: 'ExternalWikiService', active: true, project_id: different_project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when inactive `ExternalWikiService` is inserted' do
        expect do
          services.create!(type: 'ExternalWikiService', active: false, project_id: @project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when active other service is inserted' do
        expect do
          services.create!(type: 'MyService', active: true, project_id: @project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end
    end

    describe 'UPDATE trigger' do
      it 'sets `has_external_wiki` to true when `ExternalWikiService` is made active' do
        service = services.create!(type: 'ExternalWikiService', active: false, project_id: @project.id)

        expect do
          service.update!(active: true)
        end.to change { @project.reload.has_external_wiki }.to(true)
      end

      it 'sets `has_external_wiki` to false when `ExternalWikiService` is made inactive' do
        service = services.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)

        expect do
          service.update!(active: false)
        end.to change { @project.reload.has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = services.create!(type: 'ExternalWikiService', active: false, project_id: different_project.id)

        expect do
          service.update!(active: true)
        end.not_to change { @project.reload.has_external_wiki }
      end
    end

    describe 'DELETE trigger' do
      it 'sets `has_external_wiki` to false when `ExternalWikiService` is deleted' do
        service = services.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)

        expect do
          service.delete
        end.to change { @project.reload.has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when service is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = services.create!(type: 'ExternalWikiService', active: true, project_id: different_project.id)

        expect do
          service.delete
        end.not_to change { @project.reload.has_external_wiki }
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
        services.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)
      end.not_to change { @project.reload.has_external_wiki }
    end

    it 'drops the UPDATE trigger' do
      service = services.create!(type: 'ExternalWikiService', active: false, project_id: @project.id)
      @project.update!(has_external_wiki: false)

      expect do
        service.update!(active: true)
      end.not_to change { @project.reload.has_external_wiki }
    end

    it 'drops the DELETE trigger' do
      service = services.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)
      @project.update!(has_external_wiki: true)

      expect do
        service.delete
      end.not_to change { @project.reload.has_external_wiki }
    end
  end
end

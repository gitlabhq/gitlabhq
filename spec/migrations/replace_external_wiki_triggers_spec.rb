# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ReplaceExternalWikiTriggers, feature_category: :integrations do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }

  before do
    @namespace = namespaces.create!(name: 'foo', path: 'foo')
    @project = projects.create!(namespace_id: @namespace.id)
  end

  def create_external_wiki_integration(**attrs)
    attrs.merge!(type_info)

    integrations.create!(**attrs)
  end

  def has_external_wiki
    !!@project.reload.has_external_wiki
  end

  shared_examples 'external wiki triggers' do
    describe 'INSERT trigger' do
      it 'sets `has_external_wiki` to true when active external wiki integration is inserted' do
        expect do
          create_external_wiki_integration(active: true, project_id: @project.id)
        end.to change { has_external_wiki }.to(true)
      end

      it 'does not set `has_external_wiki` to true when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)

        expect do
          create_external_wiki_integration(active: true, project_id: different_project.id)
        end.not_to change { has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when inactive external wiki integration is inserted' do
        expect do
          create_external_wiki_integration(active: false, project_id: @project.id)
        end.not_to change { has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when active other service is inserted' do
        expect do
          integrations.create!(type_new: 'Integrations::MyService', type: 'MyService', active: true, project_id: @project.id)
        end.not_to change { has_external_wiki }
      end
    end

    describe 'UPDATE trigger' do
      it 'sets `has_external_wiki` to true when `ExternalWikiService` is made active' do
        service = create_external_wiki_integration(active: false, project_id: @project.id)

        expect do
          service.update!(active: true)
        end.to change { has_external_wiki }.to(true)
      end

      it 'sets `has_external_wiki` to false when integration is made inactive' do
        service = create_external_wiki_integration(active: true, project_id: @project.id)

        expect do
          service.update!(active: false)
        end.to change { has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = create_external_wiki_integration(active: false, project_id: different_project.id)

        expect do
          service.update!(active: true)
        end.not_to change { has_external_wiki }
      end
    end

    describe 'DELETE trigger' do
      it 'sets `has_external_wiki` to false when integration is deleted' do
        service = create_external_wiki_integration(active: true, project_id: @project.id)

        expect do
          service.delete
        end.to change { has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        service = create_external_wiki_integration(active: true, project_id: different_project.id)

        expect do
          service.delete
        end.not_to change { has_external_wiki }
      end
    end
  end

  describe '#up' do
    before do
      migrate!
    end

    context 'when integrations are created with the new STI value' do
      let(:type_info) { { type_new: 'Integrations::ExternalWiki' } }

      it_behaves_like 'external wiki triggers'
    end

    context 'when integrations are created with the old STI value' do
      let(:type_info) { { type: 'ExternalWikiService' } }

      it_behaves_like 'external wiki triggers'
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    let(:type_info) { { type: 'ExternalWikiService' } }

    it_behaves_like 'external wiki triggers'
  end
end

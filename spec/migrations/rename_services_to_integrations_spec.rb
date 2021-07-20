# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RenameServicesToIntegrations do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }
  let(:services) { table(:services) }

  before do
    @namespace = namespaces.create!(name: 'foo', path: 'foo')
    @project = projects.create!(namespace_id: @namespace.id)
  end

  RSpec.shared_examples 'a table (or view) with triggers' do
    describe 'INSERT tracker trigger' do
      it 'sets `has_external_issue_tracker` to true when active `issue_tracker` is inserted' do
        expect do
          subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        end.to change { @project.reload.has_external_issue_tracker }.to(true)
      end

      it 'does not set `has_external_issue_tracker` to true when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)

        expect do
          subject.create!(category: 'issue_tracker', active: true, project_id: different_project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not set `has_external_issue_tracker` to true when inactive `issue_tracker` is inserted' do
        expect do
          subject.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not set `has_external_issue_tracker` to true when a non-`issue tracker` active integration is inserted' do
        expect do
          subject.create!(category: 'my_type', active: true, project_id: @project.id)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end

    describe 'UPDATE tracker trigger' do
      it 'sets `has_external_issue_tracker` to true when `issue_tracker` is made active' do
        integration = subject.create!(category: 'issue_tracker', active: false, project_id: @project.id)

        expect do
          integration.update!(active: true)
        end.to change { @project.reload.has_external_issue_tracker }.to(true)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is made inactive' do
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.update!(active: false)
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is made inactive, and an inactive `issue_tracker` exists' do
        subject.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.update!(active: false)
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'does not change `has_external_issue_tracker` when `issue_tracker` is made inactive, if an active `issue_tracker` exists' do
        subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.update!(active: false)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not change `has_external_issue_tracker` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        integration = subject.create!(category: 'issue_tracker', active: false, project_id: different_project.id)

        expect do
          integration.update!(active: true)
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end

    describe 'DELETE tracker trigger' do
      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is deleted' do
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.delete
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'sets `has_external_issue_tracker` to false when `issue_tracker` is deleted, if an inactive `issue_tracker` still exists' do
        subject.create!(category: 'issue_tracker', active: false, project_id: @project.id)
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.delete
        end.to change { @project.reload.has_external_issue_tracker }.to(false)
      end

      it 'does not change `has_external_issue_tracker` when `issue_tracker` is deleted, if an active `issue_tracker` still exists' do
        subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: @project.id)

        expect do
          integration.delete
        end.not_to change { @project.reload.has_external_issue_tracker }
      end

      it 'does not change `has_external_issue_tracker` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        integration = subject.create!(category: 'issue_tracker', active: true, project_id: different_project.id)

        expect do
          integration.delete
        end.not_to change { @project.reload.has_external_issue_tracker }
      end
    end

    describe 'INSERT wiki trigger' do
      it 'sets `has_external_wiki` to true when active `ExternalWikiService` is inserted' do
        expect do
          subject.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)
        end.to change { @project.reload.has_external_wiki }.to(true)
      end

      it 'does not set `has_external_wiki` to true when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)

        expect do
          subject.create!(type: 'ExternalWikiService', active: true, project_id: different_project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when inactive `ExternalWikiService` is inserted' do
        expect do
          subject.create!(type: 'ExternalWikiService', active: false, project_id: @project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end

      it 'does not set `has_external_wiki` to true when active other integration is inserted' do
        expect do
          subject.create!(type: 'MyService', active: true, project_id: @project.id)
        end.not_to change { @project.reload.has_external_wiki }
      end
    end

    describe 'UPDATE wiki trigger' do
      it 'sets `has_external_wiki` to true when `ExternalWikiService` is made active' do
        integration = subject.create!(type: 'ExternalWikiService', active: false, project_id: @project.id)

        expect do
          integration.update!(active: true)
        end.to change { @project.reload.has_external_wiki }.to(true)
      end

      it 'sets `has_external_wiki` to false when `ExternalWikiService` is made inactive' do
        integration = subject.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)

        expect do
          integration.update!(active: false)
        end.to change { @project.reload.has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        integration = subject.create!(type: 'ExternalWikiService', active: false, project_id: different_project.id)

        expect do
          integration.update!(active: true)
        end.not_to change { @project.reload.has_external_wiki }
      end
    end

    describe 'DELETE wiki trigger' do
      it 'sets `has_external_wiki` to false when `ExternalWikiService` is deleted' do
        integration = subject.create!(type: 'ExternalWikiService', active: true, project_id: @project.id)

        expect do
          integration.delete
        end.to change { @project.reload.has_external_wiki }.to(false)
      end

      it 'does not change `has_external_wiki` when integration is for a different project' do
        different_project = projects.create!(namespace_id: @namespace.id)
        integration = subject.create!(type: 'ExternalWikiService', active: true, project_id: different_project.id)

        expect do
          integration.delete
        end.not_to change { @project.reload.has_external_wiki }
      end
    end
  end

  RSpec.shared_examples 'a table (or view) without triggers' do
    specify do
      number_of_triggers = ActiveRecord::Base.connection
                            .execute("SELECT count(*) FROM information_schema.triggers WHERE event_object_table = '#{subject.table_name}'")
                            .first['count']

      expect(number_of_triggers).to eq(0)
    end
  end

  describe '#up' do
    before do
      # LOCK TABLE statements must be in a transaction
      ActiveRecord::Base.transaction { migrate! }
    end

    context 'the integrations table' do
      subject { integrations }

      it_behaves_like 'a table (or view) with triggers'
    end

    context 'the services table' do
      subject { services }

      it_behaves_like 'a table (or view) without triggers'
    end
  end

  describe '#down' do
    before do
      # LOCK TABLE statements must be in a transaction
      ActiveRecord::Base.transaction do
        migration.up
        migration.down
      end
    end

    context 'the services table' do
      subject { services }

      it_behaves_like 'a table (or view) with triggers'
    end

    context 'the integrations table' do
      subject { integrations }

      it_behaves_like 'a table (or view) without triggers'
    end
  end
end

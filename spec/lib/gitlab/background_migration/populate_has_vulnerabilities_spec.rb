# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateHasVulnerabilities, schema: 20201103192526 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }
  let(:vulnerabilities) { table(:vulnerabilities) }

  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:vulnerability_base_params) { { title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, author_id: user.id } }

  let!(:project_1) { projects.create!(namespace_id: namespace.id, name: 'foo_1') }
  let!(:project_2) { projects.create!(namespace_id: namespace.id, name: 'foo_2') }
  let!(:project_3) { projects.create!(namespace_id: namespace.id, name: 'foo_3') }

  before do
    project_settings.create!(project_id: project_1.id)
    vulnerabilities.create!(vulnerability_base_params.merge(project_id: project_1.id))
    vulnerabilities.create!(vulnerability_base_params.merge(project_id: project_3.id))

    allow(::Gitlab::BackgroundMigration::Logger).to receive_messages(info: true, error: true)
  end

  describe '#perform' do
    it 'sets `has_vulnerabilities` attribute of project_settings' do
      expect { subject.perform(project_1.id, project_3.id) }.to change { project_settings.count }.from(1).to(2)
                                                            .and change { project_settings.where(has_vulnerabilities: true).count }.from(0).to(2)
    end

    it 'writes info log message' do
      subject.perform(project_1.id, project_3.id)

      expect(::Gitlab::BackgroundMigration::Logger).to have_received(:info).with(migrator: described_class.name,
                                                                                 message: 'Projects has been processed to populate `has_vulnerabilities` information',
                                                                                 count: 2)
    end

    context 'when non-existing project_id is given' do
      it 'populates only for the existing projects' do
        expect { subject.perform(project_1.id, 0, project_3.id) }.to change { project_settings.count }.from(1).to(2)
                                                                 .and change { project_settings.where(has_vulnerabilities: true).count }.from(0).to(2)
      end
    end

    context 'when an error happens' do
      before do
        allow(described_class::ProjectSetting).to receive(:upsert_for).and_raise('foo')
      end

      it 'writes error log message' do
        subject.perform(project_1.id, project_3.id)

        expect(::Gitlab::BackgroundMigration::Logger).to have_received(:error).with(migrator: described_class.name,
                                                                                    message: 'foo',
                                                                                    project_ids: [project_1.id, project_3.id])
      end
    end
  end
end

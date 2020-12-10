# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixProjectsWithoutProjectFeature, schema: 2020_01_27_111840 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }

  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let(:private_project_without_feature) { projects.create!(namespace_id: namespace.id, visibility_level: 0) }
  let(:public_project_without_feature) { projects.create!(namespace_id: namespace.id, visibility_level: 20) }
  let!(:projects_without_feature) { [private_project_without_feature, public_project_without_feature] }

  before do
    project_features.create!({ project_id: project.id, pages_access_level: 20 })
  end

  subject { described_class.new.perform(Project.minimum(:id), Project.maximum(:id)) }

  def project_feature_records
    project_features.order(:project_id).pluck(:project_id)
  end

  def features(project)
    project_features.find_by(project_id: project.id)&.attributes
  end

  it 'creates a ProjectFeature for projects without it' do
    expect { subject }.to change { project_feature_records }.from([project.id]).to([project.id, *projects_without_feature.map(&:id)])
  end

  it 'creates ProjectFeature records with default values for a public project' do
    subject

    expect(features(public_project_without_feature)).to include(
      {
        "merge_requests_access_level" => 20,
        "issues_access_level" => 20,
        "wiki_access_level" => 20,
        "snippets_access_level" => 20,
        "builds_access_level" => 20,
        "repository_access_level" => 20,
        "pages_access_level" => 20,
        "forking_access_level" => 20
      }
    )
  end

  it 'creates ProjectFeature records with default values for a private project' do
    subject

    expect(features(private_project_without_feature)).to include("pages_access_level" => 10)
  end

  context 'when access control to pages is forced' do
    before do
      allow(::Gitlab::Pages).to receive(:access_control_is_forced?).and_return(true)
    end

    it 'creates ProjectFeature records with default values for a public project' do
      subject

      expect(features(public_project_without_feature)).to include("pages_access_level" => 10)
    end
  end

  it 'sets created_at/updated_at timestamps' do
    subject

    expect(project_features.where('created_at IS NULL OR updated_at IS NULL')).to be_empty
  end
end

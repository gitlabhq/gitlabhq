# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::CreateProjectFromUploadedFileService do
  let(:file_upload) do
    fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz')
  end

  let(:params) do
    {
      path: 'path',
      namespace: user.namespace,
      name: 'name',
      file: file_upload
    }
  end

  let_it_be(:user) { create(:user) }

  subject { described_class.new(user, params) }

  it 'creates a project and returns a successful response' do
    response = nil
    expect { response = subject.execute }
      .to change(Project, :count).by(1)

    expect(response).to be_success
    expect(response.http_status).to eq(:ok)
    expect(response.payload).to be_instance_of(Project)
    expect(response.payload.name).to eq('name')
    expect(response.payload.path).to eq('path')
    expect(response.payload.namespace).to eq(user.namespace)
  end

  context 'when required parameters are not provided' do
    let(:params) { {} }

    it 'returns an erred response with the reason of the failure' do
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq("Parameter 'path' is required")

      expect(subject.errors.full_messages).to match_array([
        "Parameter 'namespace' is required",
        "Parameter 'path' is required",
        "Parameter 'file' is required"
      ])
    end
  end

  context 'when the project is invalid' do
    it 'returns an erred response with the reason of the failure' do
      create(:project, namespace: user.namespace, path: 'path')

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq('Path has already been taken')
    end
  end
end

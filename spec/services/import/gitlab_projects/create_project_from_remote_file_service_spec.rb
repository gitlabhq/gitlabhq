# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::CreateProjectFromRemoteFileService do
  let(:remote_url) { 'https://external.file.path/file' }

  let(:params) do
    {
      path: 'path',
      namespace: user.namespace,
      name: 'name',
      remote_import_url: remote_url
    }
  end

  let_it_be(:user) { create(:user) }

  subject { described_class.new(user, params) }

  it 'creates a project and returns a successful response' do
    stub_headers_for(remote_url, {
      'content-type' => 'application/gzip',
      'content-length' => '10'
    })

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

  context 'when the file url is invalid' do
    it 'returns an erred response with the reason of the failure' do
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

      params[:remote_import_url] = 'https://localhost/file'

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq('Requests to localhost are not allowed')
    end
  end

  context 'validate file type' do
    it 'returns erred response when the file type is not informed' do
      stub_headers_for(remote_url, { 'content-length' => '10' })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message)
        .to eq("Missing 'ContentType' header")
    end

    it 'returns erred response when the file type is not allowed' do
      stub_headers_for(remote_url, {
        'content-type' => 'application/js',
        'content-length' => '10'
      })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message)
        .to eq("Remote file content type 'application/js' not allowed. (Allowed content types: application/gzip)")
    end
  end

  context 'validate content type' do
    it 'returns erred response when the file size is not informed' do
      stub_headers_for(remote_url, { 'content-type' => 'application/gzip' })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message)
        .to eq("Missing 'ContentLength' header")
    end

    it 'returns error response when the file size is a text' do
      stub_headers_for(remote_url, {
        'content-type' => 'application/gzip',
        'content-length' => 'some text'
      })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message)
        .to eq("Missing 'ContentLength' header")
    end

    it 'returns erred response when the file is larger then allowed' do
      stub_headers_for(remote_url, {
        'content-type' => 'application/gzip',
        'content-length' => 11.gigabytes.to_s
      })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message)
        .to eq('Remote file larger than limit. (limit 10 GB)')
    end
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
        "Missing 'ContentLength' header",
        "Missing 'ContentType' header",
        "Parameter 'namespace' is required",
        "Parameter 'path' is required",
        "Parameter 'remote_import_url' is required"
      ])
    end
  end

  context 'when the project is invalid' do
    it 'returns an erred response with the reason of the failure' do
      create(:project, namespace: user.namespace, path: 'path')

      stub_headers_for(remote_url, {
        'content-type' => 'application/gzip',
        'content-length' => '10'
      })

      response = nil
      expect { response = subject.execute }
        .not_to change(Project, :count)

      expect(response).not_to be_success
      expect(response.http_status).to eq(:bad_request)
      expect(response.message).to eq('Path has already been taken')
    end
  end

  def stub_headers_for(url, headers = {})
    allow(Gitlab::HTTP)
      .to receive(:head)
      .with(url)
      .and_return(double(headers: headers))
  end
end

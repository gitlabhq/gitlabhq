require 'spec_helper'

describe API::Lint do
  describe 'POST /ci/lint' do
    context 'with valid .gitlab-ci.yaml content' do
      let(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      it 'passes validation' do
        post api('/ci/lint'), { content: yaml_content }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Hash
        expect(json_response['status']).to eq('valid')
        expect(json_response['errors']).to eq([])
      end
    end

    context 'with an invalid .gitlab_ci.yml' do
      it 'responds with errors about invalid syntax' do
        post api('/ci/lint'), { content: 'invalid content' }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('invalid')
        expect(json_response['errors']).to eq(['Invalid configuration format'])
      end

      it "responds with errors about invalid configuration" do
        post api('/ci/lint'), { content: '{ image: "ruby:2.1",  services: ["postgres"] }' }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq('invalid')
        expect(json_response['errors']).to eq(['jobs config should contain at least one visible job'])
      end
    end

    context 'without the content parameter' do
      it 'responds with validation error about missing content' do
        post api('/ci/lint')

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('content is missing')
      end
    end
  end
end

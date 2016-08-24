require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:yaml_content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  describe 'POST /lint' do
    context 'with valid .gitlab-ci.yaml content' do
      it 'validates content' do
        post api('/lint'), { content: yaml_content }

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Hash
        expect(json_response['status']).to eq('valid')
      end
    end

    context 'with invalid .gitlab_ci.yml' do
      it 'validates content and shows correct errors' do
        post api('/lint'), { content: 'invalid content' }

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq('invalid')
        expect(json_response['errors']).to eq(['Invalid configuration format'])
      end

      it "validates content and shows configuration error" do
        post api('/lint'), { content: '{ image: "ruby:2.1",  services: ["postgres"] }' }

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq('invalid')
        expect(json_response['errors']).to eq(['jobs config should contain at least one visible job'])
      end
    end

    context 'no content parameters' do
      it 'shows error message' do
        post api('/lint')

        expect(response).to have_http_status(400)
      end
    end
  end
end

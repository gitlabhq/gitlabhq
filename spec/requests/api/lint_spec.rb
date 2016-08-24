require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:yaml_content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  describe 'POST /lint' do
    context 'with valid .gitlab-ci.yaml content' do
      context 'authorized user' do
        it 'validate content' do
          post api('/lint'), { content: yaml_content }

          expect(response).to have_http_status(200)
          expect(json_response).to be_an Hash
          expect(json_response['status']).to eq('valid')
        end
      end
    end

    context 'with invalid .gitlab_ci.yml content' do
      it 'validate content' do
        post api('/lint'), { content: 'invalid content' }

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq('invalid')
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

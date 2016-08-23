require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:yaml_content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  describe 'POST /ci/lint' do
    context "with valid .gitlab-ci.yaml content" do
      context "authorized user" do
        it "validate content" do
          post ci_api('/lint'), { private_token: user.private_token, content: yaml_content }

          expect(response).to have_http_status(201)
          expect(json_response).to be_an Hash
          expect(json_response['status']).to eq('syntax is correct')
        end
      end

      context "unauthorized user" do
        it "does not validate content" do
          post ci_api('/lint'), { content: yaml_content }

          expect(response).to have_http_status(401)
        end
      end
    end

    context "with invalid .gitlab_ci.yml content" do
      it "validate content" do
        post ci_api('/lint'), { private_token: user.private_token, content: 'invalid content' }

        expect(response).to have_http_status(500)
        expect(json_response['status']).to eq('syntax is incorrect')
      end
    end

    context "no content" do
      it "shows error message" do
        post ci_api('/lint'), { private_token: user.private_token }

        expect(response).to have_http_status(400)
        expect(json_response['message']).to eq('Please provide content of .gitlab-ci.yml')
      end
    end
  end
end

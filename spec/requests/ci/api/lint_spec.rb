require 'spec_helper'

describe Ci::API::API do
  include ApiHelpers

  let(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  describe "Builds API for Lint" do

    describe 'POST /ci/lint' do
      before { content }

      context "with valid .gitlab-ci.yaml file" do
        it "has success status" do
          # binding.pry
          expect(response).to have_content(true)
        end
      end
    end
  end
end

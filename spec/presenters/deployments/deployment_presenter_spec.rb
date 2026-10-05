# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::DeploymentPresenter do
  let(:environment) { build_stubbed(:environment, project: build_stubbed(:project)) }
  let(:deployment) { build_stubbed(:deployment, environment: environment, project: environment.project, iid: 1) }
  let(:presenter) { described_class.new(deployment) }

  describe '#tags' do
    it do
      expect(deployment).to receive(:tags).and_return(['refs/tags/test'])
      expect(presenter.tags).to match_array([{ name: 'test', path: 'tags/test',
                                               web_path: "/#{deployment.project.full_path}/-/tags/test" }])
    end
  end

  describe '#ref_path' do
    it do
      expect(presenter.ref_path).to eq("/#{deployment.project.full_path}/-/tree/#{deployment.ref}")
    end
  end

  describe '#web_path' do
    it 'returns the path to the deployment show page' do
      expect(presenter.web_path).to eq("/#{deployment.project.full_path}/-/environments/" \
                                       "#{deployment.environment.id}/deployments/#{deployment.iid}")
    end
  end
end

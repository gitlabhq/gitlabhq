# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::DeploymentPresenter do
  let(:deployment) { create(:deployment) }
  let(:presenter) { described_class.new(deployment) }

  describe '#tags' do
    it do
      expect(deployment).to receive(:tags).and_return(['refs/tags/test'])
      expect(presenter.tags).to eq([{ name: 'test', path: 'tags/test' }])
    end
  end
end

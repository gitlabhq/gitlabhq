# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::DeploymentExtended do
  describe '#as_json' do
    subject { described_class.new(deployment).as_json }

    let(:deployment) { create(:deployment) }

    it 'includes fields from deployment entity' do
      is_expected.to include(:id, :iid, :ref, :sha, :created_at, :updated_at, :user, :environment, :deployable, :status)
    end
  end
end

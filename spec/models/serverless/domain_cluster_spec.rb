# frozen_string_literal: true

require 'spec_helper'

describe Serverless::DomainCluster do
  subject { create(:serverless_domain_cluster) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:pages_domain) }
    it { is_expected.to validate_presence_of(:knative) }
    it { is_expected.to validate_presence_of(:uuid) }

    it { is_expected.to validate_uniqueness_of(:uuid) }
    it { is_expected.to validate_length_of(:uuid).is_equal_to(14) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:pages_domain) }
    it { is_expected.to belong_to(:knative) }
    it { is_expected.to belong_to(:creator).optional }
  end
end

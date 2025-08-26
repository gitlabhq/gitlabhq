# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Slsa::Attestation, feature_category: :artifact_security do
  describe "validations" do
    subject { create(:slsa_attestation) }

    it { is_expected.to belong_to(:project) }

    it { is_expected.to belong_to(:build) }

    it { is_expected.to validate_presence_of(:predicate_kind) }
    it { is_expected.to validate_presence_of(:predicate_type) }
    it { is_expected.to validate_presence_of(:subject_digest) }

    it { is_expected.to validate_uniqueness_of(:subject_digest).scoped_to([:project_id, :predicate_kind]) }
  end
end

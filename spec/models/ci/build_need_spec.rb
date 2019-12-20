# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildNeed, model: true do
  let(:build_need) { build(:ci_build_need) }

  it { is_expected.to belong_to(:build) }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(128) }

  describe '.artifacts' do
    let_it_be(:with_artifacts)    { create(:ci_build_need, artifacts: true) }
    let_it_be(:without_artifacts) { create(:ci_build_need, artifacts: false) }

    it { expect(described_class.artifacts).to contain_exactly(with_artifacts) }
  end
end

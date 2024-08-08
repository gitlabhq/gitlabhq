# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TagEntity, feature_category: :continuous_integration do
  let_it_be(:tag) { build_stubbed(:ci_tag) }

  let(:request) { instance_double(ActionDispatch::Request) }
  let(:entity) { described_class.new(tag, request: request) }

  subject(:data) { entity.as_json }

  it { is_expected.to include(:id) }
  it { is_expected.to include(:name) }

  it { expect(data[:id]).to eq(tag.id) }
  it { expect(data[:name]).to eq(tag.name) }
end

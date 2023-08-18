# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Version, type: :model, feature_category: :pipeline_composition do
  it { is_expected.to belong_to(:release) }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:components).class_name('Ci::Catalog::Resources::Component') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:release) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }
  end
end

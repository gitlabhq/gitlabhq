# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineVariable do
  subject { build(:ci_pipeline_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:pipeline_id) }

  describe '#hook_attrs' do
    let(:variable) { create(:ci_pipeline_variable, key: 'foo', value: 'bar') }

    subject { variable.hook_attrs }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to eq({ key: 'foo', value: 'bar' }) }
  end
end

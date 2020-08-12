# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Artifactable do
  let(:ci_job_artifact) { build(:ci_job_artifact) }

  describe 'artifact properties are included' do
    context 'when enum is defined' do
      subject { ci_job_artifact }

      it { is_expected.to define_enum_for(:file_format).with_values(raw: 1, zip: 2, gzip: 3).with_suffix }
    end

    context 'when const is defined' do
      subject { ci_job_artifact.class }

      it { is_expected.to be_const_defined(:FILE_FORMAT_ADAPTERS) }
    end
  end
end

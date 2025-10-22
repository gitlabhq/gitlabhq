# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::PackageFileUploader, feature_category: :package_registry do
  describe '.workhorse_local_upload_path' do
    subject { described_class.workhorse_local_upload_path }

    it { is_expected.to eq(Rails.root.join('public/uploads/tmp/npm_package_files').to_s) }
  end

  describe '.direct_upload_enabled?' do
    subject { described_class.direct_upload_enabled? }

    it { is_expected.to be_falsey }
  end
end

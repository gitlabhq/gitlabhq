# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::CommitsUploader, feature_category: :source_code_management do
  describe '.workhorse_local_upload_path' do
    subject { described_class.workhorse_local_upload_path }

    it { is_expected.to eq(Rails.root.join('public/uploads/tmp/commits').to_s) }
  end

  describe '.direct_upload_enabled?' do
    subject { described_class.direct_upload_enabled? }

    it { is_expected.to be_falsey }
  end

  describe '.workhorse_authorize' do
    it 'returns MaximumSize' do
      expect(described_class.workhorse_authorize).to include({ MaximumSize: 300.megabytes })
    end

    context 'with GITLAB_COMMITS_MAX_REQUEST_SIZE_BYTES set' do
      before do
        stub_env('GITLAB_COMMITS_MAX_REQUEST_SIZE_BYTES', 99.megabytes.to_s)
      end

      it 'returns maximumSize' do
        expect(described_class.workhorse_authorize).to include({ MaximumSize: 99.megabytes })
      end
    end
  end
end

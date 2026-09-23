# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportData do
  describe '#merge_data' do
    it 'writes the Hash to the attribute if it is nil' do
      row = described_class.new

      row.merge_data('number' => 10)

      expect(row.data).to eq({ 'number' => 10 })
    end

    it 'merges the Hash into an existing Hash if one was present' do
      row = described_class.new(data: { 'number' => 10 })

      row.merge_data('foo' => 'bar')

      expect(row.data).to eq({ 'number' => 10, 'foo' => 'bar' })
    end
  end

  describe '#merge_credentials' do
    it 'writes the Hash to the attribute if it is nil' do
      row = described_class.new

      row.merge_credentials('number' => 10)

      expect(row.credentials).to eq({ 'number' => 10 })
    end

    it 'merges the Hash into an existing Hash if one was present' do
      row = described_class.new

      row.credentials = { 'number' => 10 }
      row.merge_credentials('foo' => 'bar')

      expect(row.credentials).to eq({ 'number' => 10, 'foo' => 'bar' })
    end
  end

  describe '#user_mapping_enabled?' do
    # See gitlab-org/gitlab#628379. User contribution mapping is the safe
    # default; only Bitbucket Server can opt out via feature flag. The
    # accessor no longer reads the stored `data` blob because that blob is
    # deleted by ProjectImportState on cancel/fail, and an attacker who
    # cancels their own import mid-flight would otherwise downgrade running
    # workers to the legacy user-resolution path.
    subject(:user_mapping_enabled?) { import_data.user_mapping_enabled? }

    context 'when there is no project' do
      let(:import_data) { described_class.new }

      it { is_expected.to be(true) }
    end

    context 'for a non-Bitbucket-Server import' do
      let(:project) { build_stubbed(:project, import_type: 'github') }
      let(:import_data) { described_class.new(project: project) }

      it { is_expected.to be(true) }

      context 'when data explicitly sets user_contribution_mapping_enabled to false' do
        let(:import_data) do
          described_class.new(project: project, data: { 'user_contribution_mapping_enabled' => false })
        end

        it { is_expected.to be(true) }
      end
    end

    context 'for a Bitbucket Server import' do
      let(:project) { build_stubbed(:project, import_type: 'bitbucket_server') }
      let(:import_data) { described_class.new(project: project) }

      context 'when the bitbucket_server_user_mapping feature flag is enabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping: true)
        end

        it { is_expected.to be(true) }
      end

      context 'when the bitbucket_server_user_mapping feature flag is disabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping: false)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::X509::Commit do
  describe '#signature' do
    let(:signature) { described_class.new(commit).signature }

    context 'returns the cached signature' do
      let(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
      let(:project) { create(:project, :public, :repository) }
      let(:commit) { create(:commit, project: project, sha: commit_sha) }

      it 'on second call' do
        allow_any_instance_of(described_class).to receive(:new).and_call_original
        expect_any_instance_of(described_class).to receive(:create_cached_signature!).and_call_original

        signature

        # consecutive call
        expect(described_class).not_to receive(:create_cached_signature!).and_call_original
        signature
      end
    end

    context 'unsigned commit' do
      let!(:project) { create :project, :repository, path: X509Helpers::User1.path }
      let!(:commit_sha) { X509Helpers::User1.commit }
      let!(:commit) { create :commit, project: project, sha: commit_sha }

      it 'returns nil' do
        expect(signature).to be_nil
      end
    end
  end
end

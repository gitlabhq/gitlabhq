# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::KeepAround do
  include RepoHelpers

  let(:repository) { create(:project, :repository).repository }
  let(:service) { described_class.new(repository) }
  let(:keep_around_ref_name) { "refs/#{::Repository::REF_KEEP_AROUND}/#{sample_commit.id}" }

  it "does not fail if we attempt to reference bad commit" do
    expect(service.kept_around?('abc1234')).to be_falsey
  end

  it "stores a reference to the specified commit sha so it isn't garbage collected" do
    service.execute([sample_commit.id])

    expect(service.kept_around?(sample_commit.id)).to be_truthy
    expect(repository.list_refs([keep_around_ref_name])).not_to be_empty
  end

  it "does not fail if writting the ref fails" do
    expect(repository.raw).to receive(:write_ref).and_raise(Gitlab::Git::CommandError)

    expect(service.kept_around?(sample_commit.id)).to be_falsey

    service.execute([sample_commit.id])

    expect(service.kept_around?(sample_commit.id)).to be_falsey
  end

  context 'for multiple SHAs' do
    it 'skips non-existent SHAs' do
      service.execute(['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', sample_commit.id])

      expect(service.kept_around?(sample_commit.id)).to be_truthy
    end

    it 'skips already-kept-around SHAs' do
      service.execute([sample_commit.id])

      expect(repository.raw_repository).to receive(:write_ref).exactly(1).and_call_original

      service.execute([sample_commit.id, another_sample_commit.id])

      expect(service.kept_around?(another_sample_commit.id)).to be_truthy
    end
  end

  context 'when disable_keep_around_refs feature flag is enabled' do
    before do
      stub_feature_flags(disable_keep_around_refs: true)
    end

    it 'does not create keep-around refs' do
      service.execute([sample_commit.id])

      expect(service.kept_around?(sample_commit.id)).to be_truthy
      expect(repository.list_refs([keep_around_ref_name])).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::KeepAround, feature_category: :gitaly do
  include RepoHelpers

  let(:repository) { create(:project, :repository).repository }
  let(:service) { described_class.new(repository) }
  let(:keep_around_ref_name) { "refs/#{::Repository::REF_KEEP_AROUND}/#{sample_commit.id}" }
  let(:metric_labels) { { source: 'keeparound_spec' } }

  def expect_metrics_change(requested, created, &block)
    requested_metric = Gitlab::Metrics.client.get(:gitlab_keeparound_refs_requested_total)
    created_metric = Gitlab::Metrics.client.get(:gitlab_keeparound_refs_created_total)

    expect(&block).to change { requested_metric.get(metric_labels) }.by(requested)
      .and change { created_metric.get(metric_labels) }.by(created)
  end

  it "does not fail if we attempt to reference bad commit" do
    expect(service.kept_around?('abc1234')).to be_falsey
  end

  it "stores a reference to the specified commit sha so it isn't garbage collected" do
    expect_metrics_change(1, 1) do
      service.execute([sample_commit.id], source: 'keeparound_spec')
    end

    expect(service.kept_around?(sample_commit.id)).to be_truthy
    expect(repository.list_refs([keep_around_ref_name])).not_to be_empty
  end

  it "does not fail if writting the ref fails" do
    expect(repository.raw).to receive(:write_ref).and_raise(Gitlab::Git::CommandError)

    expect(service.kept_around?(sample_commit.id)).to be_falsey

    expect_metrics_change(1, 0) do
      service.execute([sample_commit.id], source: 'keeparound_spec')
    end

    expect(service.kept_around?(sample_commit.id)).to be_falsey
  end

  it "returns the SHAs whose refs could not be written" do
    expect(repository.raw).to receive(:write_ref).and_raise(Gitlab::Git::CommandError)

    expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to eq([sample_commit.id])
  end

  it "returns no SHAs when every ref is written" do
    expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to be_empty
  end

  # The case the guard ordering exists for, and the only one that distinguishes it:
  # `commit_by` swallows the error and returns nil, so unless `kept_around?` runs first
  # the SHA is skipped rather than reported.
  it "returns the SHAs when the repository cannot be reached" do
    allow(repository).to receive(:commit_by).and_return(nil)
    allow(repository).to receive(:ref_exists?).and_raise(Gitlab::Git::CommandError)

    expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to eq([sample_commit.id])
  end

  # Rescued so it cannot raise out of an inline caller such as
  # `Ci::Pipeline#keep_around_commits`, but not reported: no retry can write a ref into
  # a repository that no longer exists.
  it "tracks a missing repository without reporting the SHAs or raising" do
    allow(repository).to receive(:commit_by).and_return(nil)
    allow(repository).to receive(:ref_exists?).and_raise(Gitlab::Git::Repository::NoRepository)

    expect(Gitlab::ErrorTracking).to receive(:track_exception)
      .with(an_instance_of(Gitlab::Git::Repository::NoRepository), object_id: sample_commit.id)

    expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to be_empty
  end

  it "skips SHAs whose commit is missing while the repository is reachable" do
    expect(repository).to receive(:commit_by).with(oid: sample_commit.id).and_return(nil)

    expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to be_empty
  end

  # The return value alone does not pin the guard: `kept_around?` reports true when the
  # kill switch is on, so the write would be skipped and nothing reported either way.
  # What the guard prevents is the counter and the RPC.
  it "returns no SHAs when keep-around refs are disabled" do
    stub_feature_flags(disable_keep_around_refs: true)

    expect(repository).not_to receive(:commit_by)

    expect_metrics_change(0, 0) do
      expect(service.execute([sample_commit.id], source: 'keeparound_spec')).to be_empty
    end
  end

  context 'for multiple SHAs' do
    it 'skips non-existent SHAs' do
      expect_metrics_change(1, 1) do
        service.execute(
          ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', sample_commit.id],
          source: 'keeparound_spec'
        )
      end

      expect(service.kept_around?(sample_commit.id)).to be_truthy
    end

    it 'skips already-kept-around SHAs' do
      service.execute([sample_commit.id], source: 'keeparound_spec')

      expect(repository.raw_repository).to receive(:write_ref).exactly(1).and_call_original

      expect_metrics_change(2, 1) do
        service.execute([sample_commit.id, another_sample_commit.id], source: 'keeparound_spec')
      end

      expect(service.kept_around?(another_sample_commit.id)).to be_truthy
    end
  end
end

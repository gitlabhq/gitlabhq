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

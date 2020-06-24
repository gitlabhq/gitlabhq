# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::KeepAround do
  include RepoHelpers

  let(:repository) { create(:project, :repository).repository }
  let(:service) { described_class.new(repository) }

  it "does not fail if we attempt to reference bad commit" do
    expect(service.kept_around?('abc1234')).to be_falsey
  end

  it "stores a reference to the specified commit sha so it isn't garbage collected" do
    service.execute([sample_commit.id])

    expect(service.kept_around?(sample_commit.id)).to be_truthy
  end

  it "attempting to call keep around on truncated ref does not fail" do
    service.execute([sample_commit.id])
    ref = service.send(:keep_around_ref_name, sample_commit.id)

    path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      File.join(repository.path, ref)
    end
    # Corrupt the reference
    File.truncate(path, 0)

    expect(service.kept_around?(sample_commit.id)).to be_falsey

    service.execute([sample_commit.id])

    expect(service.kept_around?(sample_commit.id)).to be_falsey

    File.delete(path)
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
end

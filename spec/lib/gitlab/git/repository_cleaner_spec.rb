require 'spec_helper'

describe Gitlab::Git::RepositoryCleaner do
  include HttpIOHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:head_sha) { repository.head_commit.id }
  let(:object_map_data) { "#{head_sha} #{'0' * 40}" }

  subject(:cleaner) { described_class.new(repository.raw) }

  describe '#apply_bfg_object_map' do
    let(:clean_refs) { %W[refs/environments/1 refs/merge-requests/1 refs/keep-around/#{head_sha}] }
    let(:keep_refs) { %w[refs/heads/_keep refs/tags/_keep] }

    before do
      (clean_refs + keep_refs).each { |ref| repository.create_ref(head_sha, ref) }
    end

    context 'from StringIO' do
      let(:object_map) { StringIO.new(object_map_data) }

      it 'removes internal references' do
        cleaner.apply_bfg_object_map(object_map)

        aggregate_failures do
          clean_refs.each { |ref| expect(repository.ref_exists?(ref)).to be_falsy }
          keep_refs.each { |ref| expect(repository.ref_exists?(ref)).to be_truthy }
        end
      end
    end

    context 'from Gitlab::HttpIO' do
      let(:url) { 'http://example.com/bfg_object_map.txt' }
      let(:tempfile) { Tempfile.new }
      let(:object_map) { Gitlab::HttpIO.new(url, object_map_data.size) }

      around do |example|
        tempfile.write(object_map_data)
        tempfile.close

        example.run
      ensure
        tempfile.unlink
      end

      it 'removes internal references' do
        stub_remote_url_200(url, tempfile.path)

        cleaner.apply_bfg_object_map(object_map)

        aggregate_failures do
          clean_refs.each { |ref| expect(repository.ref_exists?(ref)).to be_falsy }
          keep_refs.each { |ref| expect(repository.ref_exists?(ref)).to be_truthy }
        end
      end
    end
  end
end

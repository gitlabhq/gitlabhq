# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SubmoduleLinks do
  let(:submodule_item) { double(id: 'hash', path: 'gitlab-foss') }
  let(:repo) { double }
  let(:links) { described_class.new(repo) }

  describe '#for' do
    let(:ref) { 'ref' }

    subject { links.for(submodule_item, ref) }

    context 'when there is no .gitmodules file' do
      before do
        stub_urls(nil)
      end

      it 'returns no links' do
        expect(subject).to eq([nil, nil])
      end
    end

    context 'when the submodule is unknown' do
      before do
        stub_urls({ 'path' => 'url' })
      end

      it 'returns no links' do
        expect(subject).to eq([nil, nil])
      end
    end

    context 'when the submodule is known' do
      before do
        stub_urls({ 'gitlab-foss' => 'git@gitlab.com:gitlab-org/gitlab-foss.git' })
      end

      it 'returns links and caches the by ref' do
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash'])

        cache_store = links.instance_variable_get("@cache_store")

        expect(cache_store[ref]).to eq({ "gitlab-foss" => "git@gitlab.com:gitlab-org/gitlab-foss.git" })
      end

      context 'when ref name contains a dash' do
        let(:ref) { 'signed-commits' }

        it 'returns links' do
          expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-foss', 'https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash'])
        end
      end
    end
  end

  def stub_urls(urls)
    allow(repo).to receive(:submodule_urls_for).and_return(urls)
  end
end

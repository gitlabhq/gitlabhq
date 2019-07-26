# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SubmoduleLinks do
  let(:submodule_item) { double(id: 'hash', path: 'gitlab-ce') }
  let(:repo) { double }
  let(:links) { described_class.new(repo) }

  describe '#for' do
    subject { links.for(submodule_item, 'ref') }

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
        stub_urls({ 'gitlab-ce' => 'git@gitlab.com:gitlab-org/gitlab-ce.git' })
      end

      it 'returns links' do
        expect(subject).to eq(['https://gitlab.com/gitlab-org/gitlab-ce', 'https://gitlab.com/gitlab-org/gitlab-ce/tree/hash'])
      end
    end
  end

  def stub_urls(urls)
    allow(repo).to receive(:submodule_urls_for).and_return(urls)
  end
end

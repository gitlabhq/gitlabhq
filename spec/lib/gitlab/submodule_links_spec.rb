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
        expect(subject).to be_nil
      end
    end

    context 'when the submodule is unknown' do
      before do
        stub_urls({ 'path' => 'url' })
      end

      it 'returns no links' do
        expect(subject).to be_nil
      end
    end

    context 'when the submodule is known' do
      before do
        gitlab_foss = 'git@gitlab.com:gitlab-org/gitlab-foss.git'

        stub_urls({
          'ref' => { 'gitlab-foss' => gitlab_foss },
          'other_ref' => { 'gitlab-foss' => gitlab_foss },
          'signed-commits' => { 'gitlab-foss' => gitlab_foss },
          'special_ref' => { 'gitlab-foss' => 'git@OTHER.com:gitlab-org/gitlab-foss.git' }
        })
      end

      it 'returns links and caches the by ref' do
        aggregate_failures do
          expect(subject.web).to eq('https://gitlab.com/gitlab-org/gitlab-foss')
          expect(subject.tree).to eq('https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash')
          expect(subject.compare).to be_nil
        end

        cache_store = links.instance_variable_get(:@cache_store)

        expect(cache_store[ref]).to eq({ "gitlab-foss" => "git@gitlab.com:gitlab-org/gitlab-foss.git" })
      end

      context 'when ref name contains a dash' do
        let(:ref) { 'signed-commits' }

        it 'returns links' do
          aggregate_failures do
            expect(subject.web).to eq('https://gitlab.com/gitlab-org/gitlab-foss')
            expect(subject.tree).to eq('https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash')
            expect(subject.compare).to be_nil
          end
        end
      end

      context 'and the diff information is available' do
        let(:old_ref) { 'other_ref' }
        let(:diff_file) { double(old_blob: double(id: 'old-hash', path: 'gitlab-foss'), old_content_sha: old_ref) }

        subject { links.for(submodule_item, ref, diff_file) }

        it 'the returned links include the compare link' do
          aggregate_failures do
            expect(subject.web).to eq('https://gitlab.com/gitlab-org/gitlab-foss')
            expect(subject.tree).to eq('https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash')
            expect(subject.compare).to eq('https://gitlab.com/gitlab-org/gitlab-foss/-/compare/old-hash...hash')
          end
        end

        context 'but the submodule url has changed' do
          let(:old_ref) { 'special_ref' }

          it 'the returned links do not include the compare link' do
            aggregate_failures do
              expect(subject.web).to eq('https://gitlab.com/gitlab-org/gitlab-foss')
              expect(subject.tree).to eq('https://gitlab.com/gitlab-org/gitlab-foss/-/tree/hash')
              expect(subject.compare).to be_nil
            end
          end
        end
      end
    end
  end

  def stub_urls(urls_by_ref)
    allow(repo).to receive(:submodule_urls_for) do |ref|
      urls_by_ref[ref] if urls_by_ref
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RefFinder, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let(:sha) { project&.commit&.sha }

  describe '#find_by_sha' do
    subject(:find_by_sha) { described_class.new(project).find_by_sha(sha) }

    context 'when sha matches a branch', :use_clean_rails_redis_caching do
      it 'returns the branch name' do
        expect(find_by_sha).to eq('2-mb-file')
      end

      it 'caches branch name and calls Gitaly only once' do
        expect(project.repository).to receive(:branch_names_contains).once.and_call_original

        2.times do
          described_class.new(project).find_by_sha(sha)
        end
      end

      context 'when sha matches a tag', :use_clean_rails_redis_caching do
        let(:tag_name) { 'v1.1.0' }
        let(:sha) { project.repository.find_tag(tag_name).dereferenced_target.sha }

        before do
          # the sha of v1.1.0 is also in a a branch so we fake that it's not
          allow(project.repository).to receive(:branch_names_contains).and_return([])
        end

        it 'returns the tag name' do
          expect(find_by_sha).to eq(tag_name)
        end

        it 'caches tag name and calls Gitaly only once' do
          expect(project.repository).to receive(:tag_names_contains).once.and_call_original

          2.times do
            described_class.new(project).find_by_sha(sha)
          end
        end
      end
    end

    context 'when project does not exist' do
      let(:project) { nil }

      it 'returns nil' do
        expect(find_by_sha).to be_nil
      end
    end

    context 'when sha does not exist' do
      let(:sha) { 'invalid-sha' }

      it 'returns nil' do
        expect(find_by_sha).to be_nil
      end
    end

    context 'when repository does not exist' do
      before do
        allow(project).to receive(:repository_exists?).and_return(false)
      end

      it 'returns nil' do
        expect(find_by_sha).to be_nil
      end
    end
  end
end

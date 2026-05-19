# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefsByPaginationService, feature_category: :source_code_management do
  let(:default_per_page) { 20 }

  let_it_be(:project, freeze: false) { create(:project, :repository) }
  let_it_be(:protected_branch, freeze: false) { create(:protected_branch, project: project, name: 'feature*') }
  let_it_be(:protected_tag) { create(:protected_tag, project: project, name: 'v*') }

  subject(:service) { described_class.new(protected_ref, project, params) }

  shared_examples 'pagination logic' do
    describe 'with pagination' do
      before do
        allow_next_instance_of(Gitlab::Git::Finders::RefsFinder) do |finder|
          allow(finder).to receive_messages(execute: refs_from_finder, next_cursor: next_cursor)
        end
      end

      context 'when Gitaly returns a next cursor' do
        let(:next_cursor) { "refs/#{ref_prefix}/feature-next" }
        let(:refs_from_finder) do
          Array.new(default_per_page) { |i| Struct.new(:name).new("refs/#{ref_prefix}/feature-#{i}") }
        end

        it 'returns refs with a next page link' do
          refs, prev_path, next_path = service.execute

          expect(refs).to be_an(Array)
          expect(refs.size).to eq(default_per_page)
          expect(next_path).to include("page_token=#{CGI.escape(next_cursor)}")
          expect(prev_path).to be_nil
        end
      end

      context 'when Gitaly returns an empty cursor' do
        let(:next_cursor) { '' }
        let(:refs_from_finder) do
          Array.new(15) { |i| Struct.new(:name).new("refs/#{ref_prefix}/feature-#{i}") }
        end

        it 'returns refs without a next page link' do
          refs, prev_path, next_path = service.execute

          expect(refs).to be_an(Array)
          expect(refs.size).to eq(15)
          expect(next_path).to be_nil
          expect(prev_path).to be_nil
        end
      end

      context 'when Gitaly returns a nil cursor' do
        let(:next_cursor) { nil }
        let(:refs_from_finder) do
          Array.new(5) { |i| Struct.new(:name).new("refs/#{ref_prefix}/feature-#{i}") }
        end

        it 'returns refs without a next page link' do
          refs, prev_path, next_path = service.execute

          expect(refs.size).to eq(5)
          expect(next_path).to be_nil
          expect(prev_path).to be_nil
        end
      end
    end
  end

  describe 'edge cases' do
    context 'when no refs match the search' do
      let(:protected_ref) { protected_branch }
      let(:params) { { ref_type: :branches } }

      before do
        allow_next_instance_of(Gitlab::Git::Finders::RefsFinder) do |finder|
          allow(finder).to receive_messages(execute: [], next_cursor: '')
        end
      end

      it 'returns empty array with no pagination links' do
        refs, prev_path, next_path = service.execute

        expect(refs).to eq([])
        expect(prev_path).to be_nil
        expect(next_path).to be_nil
      end
    end
  end

  describe '#execute' do
    let(:params) { {} }

    context 'with unknown ref type' do
      let(:protected_ref) { protected_tag }
      let(:params) { { ref_type: :unknown } }

      it 'raises a RefsFinder::UnknownRefTypeError' do
        expect { service.execute }.to raise_error(
          Gitlab::Git::Finders::RefsFinder::UnknownRefTypeError,
          "ref_type must be one of [:branches, :tags]"
        )
      end
    end

    context 'with known ref types' do
      before do
        allow_next_instance_of(Gitlab::Git::Finders::RefsFinder) do |finder|
          allow(finder).to receive_messages(execute: mock_refs, next_cursor: '')
        end
      end

      context 'with branches' do
        let(:protected_ref) { protected_branch }
        let(:ref_type) { :branches }
        let(:ref_prefix) { 'heads' }

        let(:mock_refs) do
          [
            Struct.new(:name).new('refs/heads/feature-1'),
            Struct.new(:name).new('refs/heads/feature-2')
          ]
        end

        let(:params) { { ref_type: :branches, page_token: 'token123' } }

        describe 'RefsFinder initialization' do
          it 'creates RefsFinder with correct parameters' do
            service.execute

            expect(Gitlab::Git::Finders::RefsFinder).to have_received(:new).with(
              project.repository.raw_repository,
              ref_type: :branches,
              search: protected_branch.name,
              per_page: 20,
              page_token: 'token123'
            )
          end
        end

        include_examples 'pagination logic'
      end

      context 'with tags' do
        let(:protected_ref) { protected_tag }
        let(:ref_type) { :tags }
        let(:ref_prefix) { 'tags' }

        let(:mock_refs) do
          [
            Struct.new(:name).new('refs/tags/v1'),
            Struct.new(:name).new('refs/tags/v2')
          ]
        end

        let(:params) { { ref_type: :tags, page_token: 'token456' } }

        describe 'RefsFinder initialization' do
          it 'creates RefsFinder with correct parameters' do
            service.execute

            expect(Gitlab::Git::Finders::RefsFinder).to have_received(:new).with(
              project.repository.raw_repository,
              ref_type: :tags,
              search: protected_tag.name,
              per_page: 20,
              page_token: 'token456'
            )
          end
        end

        include_examples 'pagination logic'
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Projects::LsifDataService do
  let(:artifact) { create(:ci_job_artifact, :lsif) }
  let(:project) { build_stubbed(:project) }
  let(:path) { 'main.go' }
  let(:commit_id) { Digest::SHA1.hexdigest(SecureRandom.hex) }
  let(:params) { { path: path, commit_id: commit_id } }

  let(:service) { described_class.new(artifact.file, project, params) }

  describe '#execute' do
    context 'fetched lsif file', :use_clean_rails_memory_store_caching do
      it 'is cached' do
        service.execute

        cached_data = Rails.cache.fetch("project:#{project.id}:lsif:#{commit_id}")

        expect(cached_data.keys).to eq(%w[def_refs doc_ranges docs hover_refs ranges])
      end
    end

    context 'for main.go' do
      let(:path_prefix) { "/#{project.full_path}/-/blob/#{commit_id}" }

      it 'returns lsif ranges for the file' do
        expect(service.execute).to eq([
          {
            end_char: 9,
            end_line: 6,
            start_char: 5,
            start_line: 6,
            definition_url: "#{path_prefix}/main.go#L7"
          },
          {
            end_char: 36,
            end_line: 3,
            start_char: 1,
            start_line: 3,
            definition_url: "#{path_prefix}/main.go#L4"
          },
          {
            end_char: 12,
            end_line: 7,
            start_char: 1,
            start_line: 7,
            definition_url: "#{path_prefix}/main.go#L4"
          },
          {
            end_char: 20,
            end_line: 7,
            start_char: 13,
            start_line: 7,
            definition_url: "#{path_prefix}/morestrings/reverse.go#L11"
          },
          {
            end_char: 12,
            end_line: 8,
            start_char: 1,
            start_line: 8,
            definition_url: "#{path_prefix}/main.go#L4"
          },
          {
            end_char: 18,
            end_line: 8,
            start_char: 13,
            start_line: 8,
            definition_url: "#{path_prefix}/morestrings/reverse.go#L5"
          }
        ])
      end
    end

    context 'for morestring/reverse.go' do
      let(:path) { 'morestrings/reverse.go' }

      it 'returns lsif ranges for the file' do
        expect(service.execute.first).to eq({
          end_char: 2,
          end_line: 11,
          start_char: 1,
          start_line: 11,
          definition_url: "/#{project.full_path}/-/blob/#{commit_id}/morestrings/reverse.go#L12"
        })
      end
    end

    context 'for an unknown file' do
      let(:path) { 'unknown.go' }

      it 'returns nil' do
        expect(service.execute).to eq(nil)
      end
    end
  end

  describe '#doc_id' do
    context 'when the passed path matches multiple files' do
      let(:path) { 'check/main.go' }
      let(:docs) do
        {
          1 => 'cmd/check/main.go',
          2 => 'cmd/command.go',
          3 => 'check/main.go',
          4 => 'cmd/nested/check/main.go'
        }
      end

      it 'fetches the document with the shortest absolute path' do
        service.instance_variable_set(:@docs, docs)

        expect(service.__send__(:doc_id)).to eq(3)
      end
    end
  end
end

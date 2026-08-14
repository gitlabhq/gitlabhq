# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::GetRepositoryFileService, feature_category: :mcp_server do
  let(:service_name) { 'get_repository_file' }
  let(:service) { described_class.new(name: service_name, version: '0.1.0') }

  describe 'version registration' do
    it 'registers version 0.1.0 as the only version' do
      expect(described_class.version_exists?('0.1.0')).to be true
      expect(described_class.available_versions).to eq(['0.1.0'])
      expect(described_class.latest_version).to eq('0.1.0')
    end
  end

  describe '#input_schema' do
    subject(:schema) { service.input_schema }

    it 'requires no arguments up front' do
      expect(schema[:required]).to eq([])
    end

    it 'rejects unknown arguments' do
      expect(schema[:additionalProperties]).to be false
    end

    it 'declares project_id as a string' do
      expect(schema[:properties][:project_id][:type]).to eq('string')
    end

    it 'bounds offset and limit' do
      expect(schema[:properties][:offset]).to include(type: 'integer', minimum: 0)
      expect(schema[:properties][:limit]).to include(type: 'integer', minimum: 1, maximum: described_class::MAX_LIMIT)
    end

    it 'tells the model this is not the local filesystem' do
      expect(service.description).to include('not the local filesystem')
      expect(service.description).to include('committed at ref')
    end
  end

  describe '#annotations' do
    it 'is read only' do
      expect(service.annotations).to eq({ readOnlyHint: true })
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:ref) { project.default_branch }
    let(:text_file) { 'files/ruby/popen.rb' }

    before_all do
      project.add_developer(user)
    end

    before do
      service.set_cred(current_user: user)
    end

    def call(args)
      service.execute(params: { arguments: args })
    end

    def base_args(overrides = {})
      { 'project_id' => project.full_path, 'file_path' => text_file, 'ref' => ref }.merge(overrides)
    end

    def error_text(result)
      result[:content].first[:text]
    end

    context 'when the whole file fits in one window' do
      it 'returns the full content and reports it as not truncated' do
        result = call(base_args)
        payload = result[:structuredContent]
        expected = project.repository.blob_at(ref, text_file).data

        expect(result[:isError]).to be_falsey
        expect(payload[:path]).to eq(text_file)
        expect(payload[:ref]).to eq(ref)
        expect(payload[:content]).to eq(expected)
        expect(payload[:metadata][:total_lines]).to eq(expected.lines.size)
        expect(payload[:metadata][:returned_lines]).to eq({ start: 1, end: expected.lines.size })
        expect(payload[:metadata][:truncated]).to be false
        expect(payload[:metadata][:size_bytes]).to eq(expected.bytesize)
      end

      it 'omits system_instruction' do
        expect(call(base_args)[:structuredContent]).not_to have_key(:system_instruction)
      end
    end

    context 'with offset and limit' do
      it 'returns the requested window with 1-indexed returned_lines' do
        payload = call(base_args('offset' => 5, 'limit' => 3))[:structuredContent]
        lines = project.repository.blob_at(ref, text_file).data.lines

        expect(payload[:content]).to eq(lines[5, 3].join)
        expect(payload[:metadata][:returned_lines]).to eq({ start: 6, end: 8 })
        expect(payload[:metadata][:truncated]).to be true
      end

      it 'states the exact next offset and limit' do
        payload = call(base_args('offset' => 0, 'limit' => 2))[:structuredContent]
        remaining = payload[:metadata][:total_lines] - 2

        expect(payload[:system_instruction])
          .to eq("File truncated. Remaining lines: #{remaining}. To view more, call again with " \
            "{\"offset\": 2, \"limit\": 2}.")
      end

      it 'reassembles byte for byte when the caller follows each next offset' do
        whole = project.repository.blob_at(ref, text_file).data
        accumulated = +''
        offset = 0

        10.times do
          payload = call(base_args('offset' => offset, 'limit' => 4))[:structuredContent]
          accumulated << payload[:content]
          offset += 4
          break if offset >= payload[:metadata][:total_lines]
        end

        expect(accumulated).to eq(whole)
      end

      it 'reports an offset past the end of the file' do
        payload = call(base_args('offset' => 9999))[:structuredContent]

        expect(payload[:content]).to eq('')
        expect(payload[:metadata][:returned_lines]).to be_nil
        expect(payload[:system_instruction]).to include('past the end of the file')
      end
    end

    context 'when the retrieved content is smaller than the full blob size' do
      # Truncation is inferred from rawSize vs the capped rawTextBlob.
      let(:retrieved) { "one\ntwo\nthree\n" }

      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          'data' => {
            'project' => { 'repository' => { 'blobs' => { 'nodes' => [
              { 'path' => text_file, 'size' => 5000, 'rawSize' => 5000,
                'rawTextBlob' => retrieved, 'storedExternally' => false, 'externalStorage' => nil }
            ] } } }
          }
        )
      end

      it 'reports truncated and reports the full size' do
        payload = call(base_args)[:structuredContent]

        expect(payload[:content]).to eq(retrieved)
        expect(payload[:metadata][:returned_lines][:start]).to eq(1)
        expect(payload[:metadata][:truncated]).to be true
        expect(payload[:metadata][:size_bytes]).to eq(5000)
        expect(payload[:system_instruction]).to include('total_lines counts only the portion')
      end
    end

    context 'when the window exceeds the byte cap' do
      let(:tool) { ::Mcp::Tools::Repositories::GetRepositoryFileTool }
      let(:content) { "aaaa\nbbbb\ncccc\n" } # 15 bytes across 3 lines

      before do
        stub_const("#{tool}::MAX_WINDOW_BYTES", 8)
        allow(GitlabSchema).to receive(:execute).and_return(
          'data' => {
            'project' => { 'repository' => { 'blobs' => { 'nodes' => [
              { 'path' => text_file, 'size' => content.bytesize, 'rawSize' => content.bytesize,
                'rawTextBlob' => content, 'storedExternally' => false, 'externalStorage' => nil }
            ] } } }
          }
        )
      end

      it 'shortens the window to stay under the cap and flags it' do
        payload = call(base_args)[:structuredContent]

        expect(payload[:content].bytesize).to be <= 8
        expect(payload[:metadata][:truncated]).to be true
        expect(payload[:metadata][:returned_lines][:end]).to be < 3
        expect(payload[:system_instruction]).to include('shortened to stay within')
      end
    end

    context 'when a single line is larger than the byte cap' do
      let(:tool) { ::Mcp::Tools::Repositories::GetRepositoryFileTool }
      let(:content) { "#{'a' * 20}\n" } # one line, larger than the cap

      before do
        stub_const("#{tool}::MAX_WINDOW_BYTES", 8)
        allow(GitlabSchema).to receive(:execute).and_return(
          'data' => {
            'project' => { 'repository' => { 'blobs' => { 'nodes' => [
              { 'path' => text_file, 'size' => content.bytesize, 'rawSize' => content.bytesize,
                'rawTextBlob' => content, 'storedExternally' => false, 'externalStorage' => nil }
            ] } } }
          }
        )
      end

      it 'cuts the line and tells the caller its remainder is unretrievable' do
        payload = call(base_args)[:structuredContent]

        expect(payload[:content].bytesize).to eq(8)
        expect(payload[:metadata][:truncated]).to be true
        expect(payload[:system_instruction]).to include('its remainder is not retrievable due to size')
      end
    end

    context 'with line endings and trailing newlines' do
      let_it_be(:crlf_project) { create(:project, :repository) }

      before_all do
        crlf_project.add_developer(user)
        crlf_project.repository.create_file(
          user, 'crlf.txt', "alpha\r\nbeta\r\n\r\n\r\n", message: 'crlf', branch_name: 'master'
        )
      end

      it 'returns the bytes verbatim and counts trailing blank lines' do
        payload = call({ 'project_id' => crlf_project.full_path, 'file_path' => 'crlf.txt',
                         'ref' => 'master' })[:structuredContent]

        expect(payload[:content]).to eq("alpha\r\nbeta\r\n\r\n\r\n")
        expect(payload[:metadata][:total_lines]).to eq(4)
      end
    end

    context 'when the file cannot be returned as text' do
      it 'rejects a binary file' do
        result = call(base_args('file_path' => 'files/images/logo-black.png'))

        expect(result[:isError]).to be true
        expect(error_text(result)).to include('is binary and cannot be returned as text')
      end

      context 'with LFS enabled' do
        let_it_be_with_reload(:lfs_project) { create(:project, :repository) }

        before_all do
          lfs_project.add_developer(user)
        end

        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          lfs_project.update_attribute(:lfs_enabled, true)
        end

        it 'rejects an LFS pointer without leaking it' do
          result = call({ 'project_id' => lfs_project.full_path, 'ref' => 'master',
                          'file_path' => 'files/lfs/lfs_object.iso' })

          expect(result[:isError]).to be true
          expect(error_text(result)).to include('stored in LFS')
          expect(error_text(result)).not_to include('git-lfs.github.com')
        end
      end
    end

    context 'when the target cannot be resolved' do
      it 'distinguishes a missing ref from a missing file' do
        expect(error_text(call(base_args('ref' => 'no-such-ref')))).to include("Ref 'no-such-ref' not found")
        expect(error_text(call(base_args('file_path' => 'no/such.rb')))).to include('does not exist at ref')
      end

      it 'tells the caller not to retry a missing path' do
        expect(error_text(call(base_args('file_path' => 'no/such.rb')))).to include('Do not retry the same path')
      end

      it 'requires ref and file_path when url is absent' do
        expect(error_text(call({ 'project_id' => project.full_path, 'file_path' => text_file })))
          .to include('Provide either url, or project_id, file_path, and ref')
        expect(error_text(call({ 'project_id' => project.full_path, 'ref' => ref })))
          .to include('Provide either url, or project_id, file_path, and ref')
      end

      it 'rejects a traversing or directory path' do
        expect(error_text(call(base_args('file_path' => '../../etc/passwd')))).to include('path traversal sequence')
        expect(error_text(call(base_args('file_path' => 'files/ruby/')))).to include('must be a file, not a directory')
      end

      it 'strips a leading slash from file_path' do
        expect(call(base_args('file_path' => "/#{text_file}"))[:isError]).to be_falsey
      end
    end

    context 'with a url' do
      let(:blob_url) { "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/blob/#{ref}/#{text_file}" }

      it 'resolves project, ref and path from the url' do
        payload = call({ 'url' => blob_url, 'limit' => 2 })[:structuredContent]

        expect(payload[:path]).to eq(text_file)
        expect(payload[:ref]).to eq(ref)
      end

      it 'passes a url ref_type through to the blobs query so Gitaly can disambiguate' do
        captured = nil
        allow(GitlabSchema).to receive(:execute).and_wrap_original do |original, *args, **kwargs|
          captured = kwargs[:variables]
          original.call(*args, **kwargs)
        end

        call({ 'url' => "#{blob_url}?ref_type=tags" })

        expect(captured[:refType]).to eq('TAGS')
      end

      it 'resolves a ref containing slashes against the real ref names' do
        project.repository.add_branch(user, 'mcp-tool/with-slash', ref)
        url = "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/blob/mcp-tool/with-slash/#{text_file}"

        result = call({ 'url' => url })

        expect(result[:isError]).to be_falsey
        expect(result[:structuredContent][:ref]).to eq('mcp-tool/with-slash')
        expect(result[:structuredContent][:path]).to eq(text_file)
      end

      it 'prefers the shorter ref when the first segment is itself a branch' do
        project.repository.add_branch(user, 'feature/with-slash', ref)
        url = "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/blob/feature/with-slash/#{text_file}"

        expect(error_text(call({ 'url' => url }))).to include("does not exist at ref 'feature'")
      end

      it 'rejects a ref that contradicts the url' do
        expect(error_text(call({ 'url' => blob_url, 'ref' => 'other' }))).to include('Ref mismatch')
      end

      it 'rejects a file_path that contradicts the url' do
        expect(error_text(call({ 'url' => blob_url, 'file_path' => 'other.rb' }))).to include('File path mismatch')
      end

      it 'rejects a project path that contradicts the url' do
        expect(error_text(call({ 'url' => blob_url, 'project_id' => 'other/project' })))
          .to include('Project mismatch')
      end

      it 'rejects a url that is not a file url' do
        url = "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/tree/#{ref}/files"

        expect(error_text(call({ 'url' => url }))).to include('Invalid file URL format')
      end
    end

    context 'when the user cannot read the code' do
      let_it_be(:private_project) { create(:project, :repository, :private) }

      it 'refuses without extracting a ref from the repository' do
        expect(::ExtractsRef::RefExtractor).not_to receive(:new)

        url = "#{Gitlab.config.gitlab.url}/#{private_project.full_path}/-/blob/master/README.md"
        result = call({ 'url' => url })

        expect(result[:isError]).to be true
      end

      it 'uses the same wording as a missing project so existence cannot be inferred' do
        private_msg = error_text(call({ 'project_id' => private_project.full_path,
                                        'file_path' => 'README.md', 'ref' => 'master' }))
        missing_msg = error_text(call({ 'project_id' => 'no-group/no-project',
                                        'file_path' => 'README.md', 'ref' => 'master' }))

        expect(private_msg).to eq("Tool execution failed: Project '#{private_project.full_path}' " \
          "not found or inaccessible")
        expect(missing_msg).to eq("Tool execution failed: Project 'no-group/no-project' not found or inaccessible")
      end
    end

    context 'when current_user is not set' do
      it 'returns an error' do
        service.set_cred(current_user: nil)

        expect(error_text(call(base_args))).to include('current_user is not set')
      end
    end

    context 'when arguments fail schema validation' do
      it 'rejects a limit above the maximum' do
        expect(error_text(call(base_args('limit' => described_class::MAX_LIMIT + 1)))).to include('Validation error')
      end

      it 'rejects a negative offset' do
        expect(error_text(call(base_args('offset' => -1)))).to include('Validation error')
      end

      it 'rejects unknown arguments' do
        expect(error_text(call(base_args('nope' => 1)))).to include('Validation error')
      end
    end
  end
end

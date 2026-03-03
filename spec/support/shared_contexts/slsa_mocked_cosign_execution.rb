# frozen_string_literal: true

SLSA_ATTESTATION_BUNDLE = 'spec/fixtures/slsa/attestation.bundle'

RSpec.shared_context 'with mocked cosign execution' do
  let(:popen_result) do
    Gitlab::Popen::Result.new([], expected_stdout, expected_stderr, process_status, expected_duration)
  end

  let_it_be(:signature_bundle) { File.read(SLSA_ATTESTATION_BUNDLE) }
  let_it_be(:expected_stderr) { "expected stderr outuput string" }
  let_it_be(:expected_stdout) { "expected stderr outuput string" }
  let_it_be(:expected_duration) { 1.33337 }
  let_it_be(:expected_predicate_type) { SupplyChain::Slsa::ProvenanceStatement::PREDICATE_TYPE_V1 }
  let(:expected_predicate) { SupplyChain::Slsa::ProvenanceStatement::Predicate.from_build(build).to_json }
  let(:popen_success) { true }
  let(:process_status) do
    process_status = instance_double(Process::Status)
    allow(process_status).to receive(:success?).and_return(popen_success)

    process_status
  end

  let(:popen_stdin_file) do
    fh = instance_double(File)
    allow(fh).to receive(:write).with(any_args)
    fh
  end

  let(:real_tmp_files) do
    files = []
    3.times do
      file = Tempfile.new
      file.write(signature_bundle)
      file.flush

      files << file
    end

    files
  end

  include_context 'with build, pipeline and artifacts'

  before do
    # object_storage.rb moves the file on disk rather than use our file handle.
    # Because of this, we need to provide one Tempfile per artifact.
    nb = 0
    allow(Tempfile).to receive(:create) do |&block|
      block.call(real_tmp_files[nb])
      nb += 1
    end

    allow(Gitlab::Popen).to receive(:popen_with_detail).with(any_args).and_yield(popen_stdin_file)
      .and_return(popen_result)
  end

  after do
    real_tmp_files.each(&:close)
  end
end

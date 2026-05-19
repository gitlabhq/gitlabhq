# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'tmpdir'

require_relative '../../scripts/prepare_predictive_system_pipeline'

RSpec.describe PreparePredictiveSystemPipeline, :silence_stdout, feature_category: :tooling do
  let(:tmpdir) { Dir.mktmpdir }
  let(:duo_system_tests_file) { Tempfile.new(['duo_system_tests', '.txt'], tmpdir) }
  let(:foss_matching_tests_file) { Tempfile.new(['matching_tests_foss', '.txt'], tmpdir) }
  let(:ee_matching_tests_file) { Tempfile.new(['matching_tests_ee', '.txt'], tmpdir) }
  let(:system_full_pipeline_yml) { File.join(tmpdir, 'rspec-predictive-system-full-generated.yml') }
  let(:system_full_pipeline_template) { Tempfile.new(['system_full_template', '.yml'], tmpdir) }
  let(:skip_yml_file) { Tempfile.new(['skip', '.yml'], tmpdir) }
  let(:skip_pipeline_content) { "no-op:\n  script:\n    - echo 'skip'\n" }
  let(:pipeline_template_content) { "# full system test pipeline\nstages:\n  - test\n" }

  let(:merge_request_labels) { '' }

  subject(:pipeline) do
    described_class.new(
      duo_system_tests_path: duo_system_tests_file.path,
      foss_matching_tests_path: foss_matching_tests_file.path,
      ee_matching_tests_path: ee_matching_tests_file.path,
      system_full_pipeline_yml: system_full_pipeline_yml,
      system_full_pipeline_template: system_full_pipeline_template.path,
      merge_request_labels: merge_request_labels
    )
  end

  before do
    system_full_pipeline_template.write(pipeline_template_content)
    system_full_pipeline_template.rewind

    skip_yml_file.write(skip_pipeline_content)
    skip_yml_file.rewind
    stub_const("#{described_class}::SKIP_PIPELINE_YML_FILE", skip_yml_file.path)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  context 'when Duo ran with predictions (non-empty file)' do
    let(:duo_predictions) do
      <<~TXT
        spec/features/projects/create_spec.rb
        ee/spec/features/groups/saml_spec.rb
        spec/features/merge_requests/view_spec.rb
      TXT
    end

    before do
      duo_system_tests_file.write(duo_predictions)
      duo_system_tests_file.rewind
      foss_matching_tests_file.write('spec/features/existing_spec.rb')
      foss_matching_tests_file.rewind
    end

    it 'appends FOSS Duo predictions to the FOSS matching tests file' do
      pipeline.run!

      content = File.read(foss_matching_tests_file.path)
      expect(content).to include('spec/features/projects/create_spec.rb')
      expect(content).to include('spec/features/merge_requests/view_spec.rb')
      expect(content).to include('spec/features/existing_spec.rb')
    end

    it 'appends EE Duo predictions to the EE matching tests file' do
      pipeline.run!

      content = File.read(ee_matching_tests_file.path)
      expect(content).to include('ee/spec/features/groups/saml_spec.rb')
    end

    it 'does not mix FOSS specs into the EE file or vice versa' do
      pipeline.run!

      expect(File.read(ee_matching_tests_file.path)).not_to include('spec/features/projects/create_spec.rb')
      expect(File.read(foss_matching_tests_file.path)).not_to include('ee/spec/features/groups/saml_spec.rb')
    end

    it 'writes the skip pipeline for the full system test child pipeline' do
      pipeline.run!

      expect(File.read(system_full_pipeline_yml)).to eq(skip_pipeline_content)
    end

    it 'skips empty lines in the Duo predictions file' do
      duo_system_tests_file.truncate(0)
      duo_system_tests_file.write("\nspec/features/foo_spec.rb\n\n")
      duo_system_tests_file.rewind
      foss_matching_tests_file.truncate(0)
      foss_matching_tests_file.rewind

      pipeline.run!

      content = File.read(foss_matching_tests_file.path)
      expect(content.split).to eq(['spec/features/foo_spec.rb'])
    end

    it 'ignores specs that are neither FOSS nor EE paths' do
      duo_system_tests_file.truncate(0)
      duo_system_tests_file.write("spec/features/foo_spec.rb\nvendor/other_spec.rb\nee/spec/features/bar_spec.rb\n")
      duo_system_tests_file.rewind
      foss_matching_tests_file.truncate(0)
      foss_matching_tests_file.rewind

      pipeline.run!

      expect(File.read(foss_matching_tests_file.path).split).to eq(['spec/features/foo_spec.rb'])
      expect(File.read(ee_matching_tests_file.path).split).to eq(['ee/spec/features/bar_spec.rb'])
    end

    it 'does not duplicate specs already present in the filter file' do
      # All FOSS predictions already exist in the filter file; unique_new will be empty
      foss_matching_tests_file.truncate(0)
      foss_matching_tests_file.write('spec/features/projects/create_spec.rb spec/features/merge_requests/view_spec.rb')
      foss_matching_tests_file.rewind
      duo_system_tests_file.truncate(0)
      duo_system_tests_file.write("spec/features/projects/create_spec.rb\nspec/features/merge_requests/view_spec.rb\n")
      duo_system_tests_file.rewind

      pipeline.run!

      expect(File.read(foss_matching_tests_file.path).split).to eq(
        ['spec/features/projects/create_spec.rb', 'spec/features/merge_requests/view_spec.rb']
      )
    end

    it 'creates the EE filter file when it does not exist yet' do
      FileUtils.rm_f(ee_matching_tests_file.path)

      pipeline.run!

      expect(File.read(ee_matching_tests_file.path).split).to include('ee/spec/features/groups/saml_spec.rb')
    end

    it 'returns 0 from count_files when a filter file has no counterpart predictions' do
      # Only FOSS specs predicted; EE filter file absent - count_files(ee_path) returns 0
      duo_system_tests_file.truncate(0)
      duo_system_tests_file.write("spec/features/only_foss_spec.rb\n")
      duo_system_tests_file.rewind
      FileUtils.rm_f(ee_matching_tests_file.path)

      expect { pipeline.run! }.not_to raise_error
      expect(File.exist?(ee_matching_tests_file.path)).to be(false)
    end
  end

  context 'when Duo ran with 0 predictions (empty file)' do
    before do
      duo_system_tests_file.truncate(0)
      duo_system_tests_file.rewind
      foss_matching_tests_file.write('spec/models/user_spec.rb spec/features/projects/create_spec.rb')
      foss_matching_tests_file.rewind
      ee_matching_tests_file.write('ee/spec/models/group_spec.rb ee/spec/features/groups/saml_spec.rb')
      ee_matching_tests_file.rewind
    end

    it 'leaves detect-tests-selected system tests in the FOSS filter file' do
      pipeline.run!

      content = File.read(foss_matching_tests_file.path)
      expect(content).to include('spec/models/user_spec.rb')
      expect(content).to include('spec/features/projects/create_spec.rb')
    end

    it 'leaves detect-tests-selected system tests in the EE filter file' do
      pipeline.run!

      content = File.read(ee_matching_tests_file.path)
      expect(content).to include('ee/spec/models/group_spec.rb')
      expect(content).to include('ee/spec/features/groups/saml_spec.rb')
    end

    it 'writes the skip pipeline (does not trigger full system test run)' do
      pipeline.run!

      expect(File.read(system_full_pipeline_yml)).to eq(skip_pipeline_content)
    end

    it 'does not raise when a matching tests file does not exist' do
      FileUtils.rm_f(foss_matching_tests_file.path)

      expect { pipeline.run! }.not_to raise_error
    end
  end

  context 'when Duo is not confident or fails on a tier-2 pipeline' do
    let(:merge_request_labels) { 'pipeline::tier-2' }

    subject(:pipeline) do
      described_class.new(
        duo_system_tests_path: '/nonexistent/duo_output.txt',
        foss_matching_tests_path: foss_matching_tests_file.path,
        ee_matching_tests_path: ee_matching_tests_file.path,
        system_full_pipeline_yml: system_full_pipeline_yml,
        system_full_pipeline_template: system_full_pipeline_template.path,
        merge_request_labels: merge_request_labels
      )
    end

    before do
      foss_matching_tests_file.write('spec/models/user_spec.rb spec/features/projects/create_spec.rb')
      foss_matching_tests_file.rewind
      ee_matching_tests_file.write('ee/spec/models/group_spec.rb ee/spec/features/groups/saml_spec.rb')
      ee_matching_tests_file.rewind
    end

    it 'strips system tests from the FOSS matching tests file' do
      pipeline.run!

      content = File.read(foss_matching_tests_file.path)
      expect(content).to include('spec/models/user_spec.rb')
      expect(content).not_to include('spec/features/projects/create_spec.rb')
    end

    it 'strips system tests from the EE matching tests file' do
      pipeline.run!

      content = File.read(ee_matching_tests_file.path)
      expect(content).to include('ee/spec/models/group_spec.rb')
      expect(content).not_to include('ee/spec/features/groups/saml_spec.rb')
    end

    it 'does not raise when a matching tests filter file does not exist' do
      FileUtils.rm_f(foss_matching_tests_file.path)

      expect { pipeline.run! }.not_to raise_error
    end

    it 'copies the full system test pipeline template as-is' do
      pipeline.run!

      expect(File.read(system_full_pipeline_yml)).to eq(pipeline_template_content)
    end

    context 'when pipeline:spec-only label is set' do
      let(:merge_request_labels) { 'pipeline::tier-2,pipeline:spec-only' }

      it 'writes the skip pipeline' do
        pipeline.run!

        expect(File.read(system_full_pipeline_yml)).to eq(skip_pipeline_content)
      end

      it 'does not modify the matching tests files' do
        pipeline.run!

        expect(File.read(foss_matching_tests_file.path)).to include('spec/features/projects/create_spec.rb')
        expect(File.read(ee_matching_tests_file.path)).to include('ee/spec/features/groups/saml_spec.rb')
      end
    end
  end

  context 'when Duo does not run on tier-1' do
    let(:merge_request_labels) { 'pipeline::tier-1' }

    subject(:pipeline) do
      described_class.new(
        duo_system_tests_path: '/nonexistent/path.txt',
        foss_matching_tests_path: foss_matching_tests_file.path,
        ee_matching_tests_path: ee_matching_tests_file.path,
        system_full_pipeline_yml: system_full_pipeline_yml,
        system_full_pipeline_template: system_full_pipeline_template.path,
        merge_request_labels: merge_request_labels
      )
    end

    it 'writes the skip pipeline' do
      pipeline.run!

      expect(File.read(system_full_pipeline_yml)).to eq(skip_pipeline_content)
    end

    it 'does not modify the FOSS matching tests file' do
      foss_matching_tests_file.write('spec/models/user_spec.rb')
      foss_matching_tests_file.rewind

      pipeline.run!

      expect(File.read(foss_matching_tests_file.path)).to eq('spec/models/user_spec.rb')
    end
  end
end

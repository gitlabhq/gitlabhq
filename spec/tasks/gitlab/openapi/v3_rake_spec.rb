# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require_relative '../../../support/silence_stdout'

RSpec.describe 'gitlab:openapi:v3 namespace rake tasks', :silence_stdout, feature_category: :api do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/openapi/v3'
    Rake::Task.define_task(:environment)
    Rake::Task.define_task(:enable_feature_flags)
  end

  # Stub API and Grape constants before loading the rake tasks
  # to prevent loading files that require the full Rails environment
  before do
    stub_const('Grape::API::Instance', Class.new)
    # Stub the API namespace itself, otherwise stubbing the constants below autoloads the real ones
    stub_const('API', Module.new)
    stub_const('API::API', Class.new)
    stub_const('API::Base', Class.new)
    stub_const('Grape::Entity', Class.new)
  end

  let(:yaml_v3_doc_introduction) { Tasks::Gitlab::Openapi::V3Document::INTRODUCTION }

  shared_context 'with openapi v3 generator setup' do
    let(:generator) { instance_double(Gitlab::GrapeOpenapi::Generator) }
    let(:generated_spec) { { 'openapi' => '3.0.0', 'info' => { 'title' => 'GitLab API', 'version' => '19.3' } } }
    let(:yaml_content) { "---\nopenapi: 3.0.0\ninfo:\n  title: GitLab API\n  version: '19.3'\n" }
    let(:api_descendants) { [Class.new, Class.new, Class.new] }
    let(:entity_descendants) { [Class.new, Class.new, Class.new] }

    before do
      stub_const('Gitlab::GrapeOpenapi::Generator', Class.new)

      allow(API::Base).to receive(:descendants).and_return(api_descendants)
      allow(Grape::Entity).to receive(:descendants).and_return(entity_descendants)
      allow(Gitlab::GrapeOpenapi::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate).and_return(generated_spec)
    end
  end

  shared_examples_for 'gitlab:openapi:v3:validate' do
    let(:expected_yarn_command) { 'yarn swagger:validate doc/api/openapi/openapi_v3.yaml' }

    context 'when in development environment' do
      before do
        allow(Rails).to receive_message_chain(:env, :development?).and_return(true)
      end

      it 'validates the OpenAPI documentation' do
        expect(main_object).to receive(:system).with(expected_yarn_command).and_return(true)
        run_rake_task('gitlab:openapi:v3:validate')
      end

      context 'when the validation succeeds' do
        it 'completes successfully' do
          allow(main_object).to receive(:system).with(expected_yarn_command).and_return(true)
          expect { run_rake_task('gitlab:openapi:v3:validate') }.not_to raise_error
        end
      end

      context 'when the validation fails' do
        before do
          allow(main_object).to receive(:system).with(expected_yarn_command).and_return(false)
        end

        it 'aborts with the expected error message' do
          expect { run_rake_task('gitlab:openapi:v3:validate') }
            .to raise_error(SystemExit).and output(/Validation of swagger document failed/).to_stderr
        end
      end
    end

    context 'when not in development environment' do
      before do
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      end

      it 'raises the expected RuntimeError error' do
        expect { run_rake_task('gitlab:openapi:v3:validate') }
          .to raise_error(RuntimeError, 'This task can only be run in the development environment')
      end
    end
  end

  shared_examples_for 'gitlab:openapi:v3:generate' do
    include_context 'with openapi v3 generator setup'

    it 'generates the OpenAPI v3 documentation' do
      stub_env('OPENAPI_SIMULATE_SAAS', nil)

      expect(Gitlab::GrapeOpenapi::Generator).to receive(:new).with(
        api_classes: api_descendants
      ).and_return(generator)

      expect(generator).to receive(:generate).and_return(generated_spec)
      expect(File).to receive(:write).with('doc/api/openapi/openapi_v3.yaml', yaml_v3_doc_introduction + yaml_content)
      expect(ENV).to receive(:[]=).with('GITLAB_SIMULATE_SAAS', 'false').and_call_original
      allow(ENV).to receive(:[]=).and_call_original

      expect { run_rake_task('gitlab:openapi:v3:generate') }
        .to output(/GITLAB_SIMULATE_SAAS=false/).to_stdout
    end

    context 'when OPENAPI_SIMULATE_SAAS is set' do
      before do
        stub_env('OPENAPI_SIMULATE_SAAS', 'true')
      end

      it 'forwards the value to GITLAB_SIMULATE_SAAS' do
        allow(generator).to receive(:generate).and_return(generated_spec)
        allow(File).to receive(:write)
        expect(ENV).to receive(:[]=).with('GITLAB_SIMULATE_SAAS', 'true').and_call_original
        allow(ENV).to receive(:[]=).and_call_original

        expect { run_rake_task('gitlab:openapi:v3:generate') }
          .to output(/GITLAB_SIMULATE_SAAS=true/).to_stdout
      end
    end

    context 'when not on test or development environments' do
      let(:expected_error_message) { 'This task can only be run in the development or test environment' }

      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      end

      it 'raises an error' do
        expect { run_rake_task('gitlab:openapi:v3:generate') }.to raise_error(RuntimeError, expected_error_message)
      end
    end
  end

  describe 'gitlab:openapi:v3:validate' do
    it_behaves_like 'gitlab:openapi:v3:validate'
  end

  describe 'gitlab:openapi:v3:generate' do
    it_behaves_like 'gitlab:openapi:v3:generate'
  end

  describe 'gitlab:openapi:v3:generate_and_check' do
    it_behaves_like 'gitlab:openapi:v3:validate'
    it_behaves_like 'gitlab:openapi:v3:generate'
  end

  describe 'gitlab:openapi:v3:check_docs' do
    include_context 'with openapi v3 generator setup'

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
        .and_return(yaml_v3_doc_introduction + yaml_content)
    end

    it 'passes when documentation is up to date' do
      expect { run_rake_task('gitlab:openapi:v3:check_docs') }.to output(
        /OpenAPI v3 documentation is up to date/).to_stdout
    end

    it 'defaults GITLAB_SIMULATE_SAAS to false' do
      stub_env('OPENAPI_SIMULATE_SAAS', nil)
      expect(ENV).to receive(:[]=).with('GITLAB_SIMULATE_SAAS', 'false').and_call_original
      allow(ENV).to receive(:[]=).and_call_original

      expect { run_rake_task('gitlab:openapi:v3:check_docs') }
        .to output(/GITLAB_SIMULATE_SAAS=false/).to_stdout
    end

    it 'forwards OPENAPI_SIMULATE_SAAS to GITLAB_SIMULATE_SAAS when set' do
      stub_env('OPENAPI_SIMULATE_SAAS', 'true')
      expect(ENV).to receive(:[]=).with('GITLAB_SIMULATE_SAAS', 'true').and_call_original
      allow(ENV).to receive(:[]=).and_call_original

      expect { run_rake_task('gitlab:openapi:v3:check_docs') }
        .to output(/GITLAB_SIMULATE_SAAS=true/).to_stdout
    end

    context 'when documentation is outdated' do
      let(:outdated_yaml) { "---\nopenapi: 3.0.0\ninfo:\n  title: Outdated API\n  version: '19.3'\n" }

      before do
        allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
          .and_return(yaml_v3_doc_introduction + outdated_yaml)
      end

      it 'aborts with correct message when documentation is outdated' do
        expect { run_rake_task('gitlab:openapi:v3:check_docs') }.to output(
          %r{OpenAPI documentation is outdated! Please update it by running `bin/rake gitlab:openapi:v3:generate`}
        ).to_stdout.and raise_error(SystemExit)
      end
    end

    context 'when only info.version differs' do
      let(:other_milestone_yaml) { "---\nopenapi: 3.0.0\ninfo:\n  title: GitLab API\n  version: '19.4'\n" }

      before do
        allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
          .and_return(yaml_v3_doc_introduction + other_milestone_yaml)
      end

      it 'passes, so release tags that rewrite the milestone do not fail the check' do
        expect { run_rake_task('gitlab:openapi:v3:check_docs') }.to output(
          /OpenAPI v3 documentation is up to date/).to_stdout
      end
    end

    context 'when the committed document is indented differently' do
      let(:four_space_yaml) { "---\nopenapi: 3.0.0\ninfo:\n    title: GitLab API\n    version: 19.3.0-rc42-ee\n" }

      before do
        allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
          .and_return(yaml_v3_doc_introduction + four_space_yaml)
      end

      # Reporting the bad milestone rather than a missing field proves the lookup does not
      # depend on the emitted indentation.
      it 'still locates info.version' do
        expect { run_rake_task('gitlab:openapi:v3:check_docs') }
          .to raise_error(SystemExit)
          .and output(/committed: info\.version must be a MAJOR\.MINOR milestone/).to_stderr
      end
    end

    context 'when an earlier section has its own version key' do
      let(:generated_spec) do
        {
          'components' => { 'version' => 'not-a-milestone' },
          'info' => { 'title' => 'GitLab API', 'version' => '19.3' }
        }
      end

      let(:decoy_yaml) do
        "---\ncomponents:\n  version: not-a-milestone\ninfo:\n  title: GitLab API\n  version: '19.4'\n"
      end

      before do
        allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
          .and_return(yaml_v3_doc_introduction + decoy_yaml)
      end

      # Passing proves info.version was the field read and the line removed: had the decoy been
      # picked up instead, its value would have failed the milestone check.
      it 'reads and removes the one belonging to info' do
        expect { run_rake_task('gitlab:openapi:v3:check_docs') }.to output(
          /OpenAPI v3 documentation is up to date/).to_stdout
      end
    end

    context 'when the committed info.version is unusable' do
      using RSpec::Parameterized::TableSyntax

      where(:case_name, :version_line, :expected_message) do
        'a full version' | "  version: 19.3.0-rc42-ee\n" | 'committed: info.version must be a MAJOR.MINOR milestone'
        'absent'         | ""                            | 'committed: info.version is missing'
      end

      with_them do
        before do
          allow(File).to receive(:read).with('doc/api/openapi/openapi_v3.yaml')
            .and_return("#{yaml_v3_doc_introduction}---\nopenapi: 3.0.0\ninfo:\n  title: GitLab API\n#{version_line}")
        end

        it 'aborts naming the offending document' do
          expect { run_rake_task('gitlab:openapi:v3:check_docs') }
            .to raise_error(SystemExit)
            .and output(/#{Regexp.escape(expected_message)}/).to_stderr
        end
      end
    end

    context "when debug is enabled" do
      let(:outdated_yaml) { "---\nopenapi: 3.0.0\ninfo:\n  title: Outdated API\n  version: '19.3'\n" }
      let(:verbose) { Rake::FileUtilsExt.verbose }
      let(:nowrite) { Rake::FileUtilsExt.nowrite }
      let(:expected_command) { "diff -u doc/api/openapi/openapi_v3.yaml doc/api/openapi/openapi_v3.yaml.generated" }

      before do
        stub_env("OPENAPI_CHECK_DEBUG", "true")

        allow(File).to receive(:read).with("doc/api/openapi/openapi_v3.yaml")
          .and_return(yaml_v3_doc_introduction + outdated_yaml)
        allow(File).to receive(:write).with("doc/api/openapi/openapi_v3.yaml.generated", anything)
      end

      it "writes the yaml content to the expected file and outputs the diff with it" do
        expect(File).to receive(:write).with("doc/api/openapi/openapi_v3.yaml.generated", anything)
        expect(main_object).to receive(:sh).with(expected_command)
        expect { run_rake_task("gitlab:openapi:v3:check_docs") }.to raise_error(SystemExit)
      end

      context "when the committed info.version differs from the generated one" do
        let(:outdated_yaml) { "---\nopenapi: 3.0.0\ninfo:\n  title: Outdated API\n  version: '19.4'\n" }

        it "carries over the committed info.version so the diff does not report it" do
          expect(File).to receive(:write)
            .with("doc/api/openapi/openapi_v3.yaml.generated", a_string_including("  version: '19.4'"))
          allow(main_object).to receive(:sh)

          expect { run_rake_task("gitlab:openapi:v3:check_docs") }.to raise_error(SystemExit)
        end
      end
    end
  end
end

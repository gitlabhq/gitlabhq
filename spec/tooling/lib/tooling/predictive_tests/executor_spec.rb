# frozen_string_literal: true

require "tmpdir"
require "fast_spec_helper"

require_relative "../../../../../tooling/lib/tooling/predictive_tests/executor"

RSpec.describe Tooling::PredictiveTests::Executor, feature_category: :tooling do
  subject(:predictive_tests) { described_class.new(options) }

  let!(:temp_dir) { Dir.mktmpdir }
  let(:changed_files) { ["some_changed_file"] }
  let(:changed_files_finder_input) { changed_files }
  let(:all_changed_files) { changed_files_finder_input + ["extra_changed_file"] }
  let(:changed_files_manual_input) { nil }
  let(:js_changed_files) { ["additional_changed.js"] }
  let(:rspec_spec_list) { ["spec/a_spec.rb", "b_spec.rb", "ee/spec/b_spec.rb"] }
  let(:ci) { true }
  let(:use_duo) { false }
  let(:logger) { Logger.new(StringIO.new) }

  let(:test_selector) do
    instance_double(Tooling::PredictiveTests::TestSelector, rspec_spec_list: rspec_spec_list)
  end

  let(:find_changes) do
    instance_double(Tooling::FindChanges, execute: changed_files)
  end

  let(:mapping_fetcher) do
    instance_double(
      Tooling::PredictiveTests::MappingFetcher,
      fetch_rspec_mappings: "test_mapping_file.json",
      fetch_frontend_fixtures_mappings: options[:frontend_fixtures_mapping_path]
    )
  end

  let(:options) do
    {
      ci: ci,
      debug: false,
      with_crystalball_mappings: true,
      mapping_type: :described_class,
      with_frontend_fixture_mappings: true,
      use_duo: use_duo,
      changed_files: changed_files_manual_input,
      changed_files_path: File.join(temp_dir, "changed_files.txt"),
      frontend_fixtures_mapping_path: File.join(temp_dir, "frontend_fixtures_mapping.json"),
      matching_foss_rspec_test_files_path: File.join(temp_dir, "foss_tests.txt"),
      matching_ee_rspec_test_files_path: File.join(temp_dir, "ee_tests.txt"),
      matching_js_files_path: File.join(temp_dir, "js_files.txt")
    }
  end

  before do
    allow(Logger).to receive(:new).and_return(logger)

    allow(Tooling::FindChanges).to receive(:new)
      .with(from: :api, frontend_fixtures_mapping_pathname: options[:frontend_fixtures_mapping_path])
      .and_return(find_changes)
    allow(Tooling::PredictiveTests::ChangedFiles).to receive(:fetch)
      .with(changes: changed_files_finder_input)
      .and_return(all_changed_files)
    allow(Tooling::PredictiveTests::ChangedFiles).to receive(:fetch)
      .with(changes: changed_files_finder_input, with_js_files: true, with_views: true)
      .and_return(js_changed_files)
    allow(Tooling::PredictiveTests::MappingFetcher).to receive(:new)
      .with(logger: kind_of(Logger))
      .and_return(mapping_fetcher)
    allow(Tooling::PredictiveTests::TestSelector).to receive(:new)
      .with(
        changed_files: all_changed_files,
        rspec_test_mapping_path: "test_mapping_file.json",
        use_duo: use_duo,
        git_diff_content: anything,
        logger: logger
      )
      .and_return(test_selector)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with("spec/a_spec.rb").and_return(true)
    allow(File).to receive(:exist?).with("ee/spec/b_spec.rb").and_return(true)
  end

  def contents(path)
    File.read(path)
  end

  context "when run with CI enabled" do
    it "creates all output files" do
      predictive_tests.execute

      expect(contents(options[:changed_files_path])).to eq(all_changed_files.join("\n"))
      expect(contents(options[:matching_foss_rspec_test_files_path])).to eq("spec/a_spec.rb")
      expect(contents(options[:matching_ee_rspec_test_files_path])).to eq("ee/spec/b_spec.rb")
      expect(contents(options[:matching_js_files_path])).to eq(js_changed_files.join("\n"))
    end
  end

  context "with manual changed files input" do
    let(:changed_files_manual_input) { "changed_file.rb some_other_changed_file.rb" }
    let(:changed_files_finder_input) { changed_files_manual_input.split(" ") }

    it "uses changed files input" do
      predictive_tests.execute

      expect(contents(options[:changed_files_path])).to eq(all_changed_files.join("\n"))
    end
  end

  context "when running locally" do
    let(:ci) { false }
    let(:local_directory_state) { "" }

    before do
      allow(Open3).to receive(:capture2e)
        .with("git status --porcelain")
        .and_return([local_directory_state, instance_double(Process::Status, success?: true)])
      allow(Open3).to receive(:capture2e)
        .with("git diff HEAD")
        .and_return(["diff content", instance_double(Process::Status, success?: true)])
      allow(Open3).to receive(:capture2e)
        .with("git diff master...HEAD")
        .and_return(["diff content", instance_double(Process::Status, success?: true)])
    end

    context "when local directory is clean" do
      before do
        allow(Open3).to receive(:capture2e)
          .with("git rev-parse --abbrev-ref HEAD")
          .and_return(["feature-branch", instance_double(Process::Status, success?: true)])
        allow(Open3).to receive(:capture2e)
          .with("git diff --name-only master...HEAD")
          .and_return([changed_files.join("\n"), instance_double(Process::Status, success?: true)])
      end

      it "fetches branch diff and outputs to stdout" do
        expect { predictive_tests.execute }.to output(rspec_spec_list.join(" ")).to_stdout
        expect(find_changes).not_to have_received(:execute)
      end
    end

    context "when local directory has changes" do
      let(:local_directory_state) { "output" }

      before do
        allow(Open3).to receive(:capture2e)
          .with("git diff --name-only HEAD")
          .and_return([changed_files.join("\n"), instance_double(Process::Status, success?: true)])
      end

      it "fetches local changes and outputs to stdout" do
        expect { predictive_tests.execute }.to output(rspec_spec_list.join(" ")).to_stdout
        expect(find_changes).not_to have_received(:execute)
      end
    end

    context "when use_duo is enabled" do
      let(:use_duo) { true }
      let(:ci) { false }

      before do
        stub_env('CI', nil)
        stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', nil)
        allow(Open3).to receive(:capture2e)
          .with("git rev-parse --abbrev-ref HEAD")
          .and_return(["feature-branch", instance_double(Process::Status, success?: true)])
        allow(Open3).to receive(:capture2e)
          .with("git diff --name-only master...HEAD")
          .and_return([changed_files.join("\n"), instance_double(Process::Status, success?: true)])
      end

      it "passes use_duo and git_diff_content to TestSelector" do
        predictive_tests.execute

        expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
          changed_files: all_changed_files,
          rspec_test_mapping_path: "test_mapping_file.json",
          use_duo: true,
          git_diff_content: "diff content",
          logger: logger
        )
      end

      context 'when duo_system_test_files_path is set and Duo is confident' do
        let(:duo_output_path) { File.join(temp_dir, 'duo_system_test_files.txt') }
        let(:duo_confident) { true }
        let(:duo_spec_list) { ['spec/features/user_spec.rb'] }

        let(:test_selector) do
          instance_double(
            Tooling::PredictiveTests::TestSelector,
            rspec_spec_list: rspec_spec_list,
            duo_confident?: duo_confident,
            duo_spec_list: duo_spec_list
          )
        end

        let(:options) do
          super().merge(duo_system_test_files_path: duo_output_path)
        end

        before do
          allow(Tooling::PredictiveTests::TestSelector).to receive(:new).and_return(test_selector)
          allow(Open3).to receive(:capture2e)
                            .with("git diff master...HEAD")
                            .and_return(["diff content", instance_double(Process::Status, success?: true)])
        end

        it 'saves Duo predictions to disk' do
          predictive_tests.execute
          expect(File.read(duo_output_path)).to include('spec/features/user_spec.rb')
        end
      end

      context 'when in CI with CI_MERGE_REQUEST_TARGET_BRANCH_NAME set' do
        let(:ci) { true }

        before do
          stub_env('CI', 'true')
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', 'master')
          allow(Open3).to receive(:capture2e)
                            .with("git fetch origin master --depth=20")
                            .and_return(['', instance_double(Process::Status, success?: true)])
          allow(Open3).to receive(:capture2e)
                            .with("git diff origin/master...HEAD")
                            .and_return(['ci diff content', instance_double(Process::Status, success?: true)])
        end

        it 'passes CI diff content to TestSelector' do
          predictive_tests.execute
          expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
            hash_including(git_diff_content: 'ci diff content')
          )
        end
      end

      context 'when on master branch locally' do
        let(:ci) { false }

        before do
          stub_env('CI', nil)
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', nil)
          allow(Open3).to receive(:capture2e)
                            .with("git status --porcelain")
                            .and_return(['', instance_double(Process::Status, success?: true)])
          allow(Open3).to receive(:capture2e)
                            .with("git rev-parse --abbrev-ref HEAD")
                            .and_return(['master', instance_double(Process::Status, success?: true)])
          allow(Tooling::PredictiveTests::ChangedFiles).to receive(:fetch).and_return([])
          allow(Tooling::PredictiveTests::TestSelector).to receive(:new).and_return(test_selector)
        end

        it 'passes empty diff for master branch' do
          predictive_tests.execute
          expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
            hash_including(git_diff_content: '', use_duo: true)
          )
        end
      end

      context 'when Duo is not confident' do
        let(:duo_output_path) { File.join(temp_dir, 'duo_system_test_files.txt') }
        let(:duo_confident) { false }

        let(:test_selector) do
          instance_double(
            Tooling::PredictiveTests::TestSelector,
            rspec_spec_list: rspec_spec_list,
            duo_confident?: duo_confident,
            duo_spec_list: []
          )
        end

        let(:options) do
          super().merge(duo_system_test_files_path: duo_output_path)
        end

        before do
          allow(Tooling::PredictiveTests::TestSelector).to receive(:new).and_return(test_selector)
        end

        it 'does not write the Duo output file' do
          predictive_tests.execute
          expect(File).not_to exist(duo_output_path)
        end
      end

      context 'when working directory is dirty' do
        let(:ci) { false }

        before do
          stub_env('CI', nil)
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', nil)
          allow(Open3).to receive(:capture2e)
                            .with("git status --porcelain")
                            .and_return(['M some_file.rb', instance_double(Process::Status, success?: true)])
          allow(Open3).to receive(:capture2e)
                            .with("git diff --name-only HEAD")
                            .and_return([changed_files.join("\n"), instance_double(Process::Status, success?: true)])
          allow(Open3).to receive(:capture2e)
                            .with("git diff HEAD")
                            .and_return(['dirty diff', instance_double(Process::Status, success?: true)])
          allow(Tooling::PredictiveTests::TestSelector).to receive(:new).and_return(test_selector)
        end

        it 'diffs against HEAD' do
          predictive_tests.execute
          expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
            hash_including(git_diff_content: 'dirty diff', use_duo: true)
          )
        end
      end
    end

    context "when git command fails" do
      before do
        allow(Open3).to receive(:capture2e)
          .with("git status --porcelain")
          .and_return(["some error", instance_double(Process::Status, success?: false)])
      end

      it "raises an error" do
        expect { predictive_tests.execute }.to raise_error(
          "git command with args 'status --porcelain' failed! Output: some error"
        )
      end
    end
  end
end

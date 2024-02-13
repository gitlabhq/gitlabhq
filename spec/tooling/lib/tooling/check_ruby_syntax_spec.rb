# frozen_string_literal: true

require "fast_spec_helper"
require "fileutils"
require "rspec-parameterized"

require_relative "../../../../tooling/lib/tooling/check_ruby_syntax"

RSpec.describe Tooling::CheckRubySyntax, feature_category: :tooling do
  let(:files) { Dir.glob("**/*") }

  subject(:checker) { described_class.new(files) }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end

  describe "#ruby_files" do
    subject { checker.ruby_files }

    context "without files" do
      it { is_expected.to eq([]) }
    end

    context "with files ending with Ruby extensions" do
      let(:ruby_files) do
        %w[
          ruby_file.rb
          rspec.html.haml_spec.rb
          task.rake
          config.ru
        ]
      end

      let(:non_ruby_files) do
        %w[
          a.txt
          a.erb
        ]
      end

      before do
        (ruby_files + non_ruby_files).each do |file|
          FileUtils.touch(file)
        end
      end

      it { is_expected.to match_array(ruby_files) }
    end

    context "with special Ruby files" do
      let(:files) do
        %w[foo/Guardfile danger/Dangerfile gems/Gemfile Rakefile]
      end

      before do
        files.each do |file|
          FileUtils.mkdir_p(File.dirname(file))
          FileUtils.touch(file)
        end
      end

      it { is_expected.to match_array(files) }
    end
  end

  describe "#run" do
    subject(:errors) { checker.run }

    shared_examples "no errors" do
      it { is_expected.to be_empty }
    end

    context "without files" do
      include_examples "no errors"
    end

    context "with perfect Ruby code" do
      before do
        File.write("perfect.rb", "perfect = code")
      end

      include_examples "no errors"
    end

    context "with invalid Ruby code" do
      before do
        File.write("invalid.rb", "invalid,")
      end

      it "has errors" do
        expect(errors).to include(a_kind_of(SyntaxError))
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Release do
  let(:entry) { described_class.new(config) }

  shared_examples_for 'a valid entry' do
    describe '#value' do
      it 'returns release configuration' do
        expect(entry.value).to eq config
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  shared_examples_for 'reports error' do |message|
    it 'reports error' do
      expect(entry.errors)
        .to include message
    end
  end

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) { { tag_name: 'v0.06', description: "./release_changelog.txt" } }

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'assets' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          assets: [
            {
              name: "cool-app.zip",
              url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
            }
          ]
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'name' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME"
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'ref' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          ref: 'b3235930aa443112e639f941c69c578912189bdd'
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'released_at' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          released_at: '2019-03-15T08:00:00Z'
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'milestones' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          milestones: milestones
        }
      end

      context 'for an array of milestones' do
        let(:milestones) { %w[m1 m2 m3] }

        it_behaves_like 'a valid entry'
      end

      context 'for a single milestone' do
        let(:milestones) { 'm1' }

        it_behaves_like 'a valid entry'
      end
    end

    context "when value includes 'ref' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          ref: ref
        }
      end

      context "when 'ref' is a full commit SHA" do
        let(:ref) { 'b3235930aa443112e639f941c69c578912189bdd' }

        it_behaves_like 'a valid entry'
      end

      context "when 'ref' is a short commit SHA" do
        let(:ref) { 'b3235930' }

        it_behaves_like 'a valid entry'
      end

      context "when 'ref' is a branch name" do
        let(:ref) { 'fix/123-branch-name' }

        it_behaves_like 'a valid entry'
      end

      context "when 'ref' is a semantic versioning tag" do
        let(:ref) { 'v1.2.3' }

        it_behaves_like 'a valid entry'
      end

      context "when 'ref' is a semantic versioning tag rc" do
        let(:ref) { 'v1.2.3-rc' }

        it_behaves_like 'a valid entry'
      end
    end

    context "when value includes 'released_at' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          released_at: '2019-03-15T08:00:00Z'
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when value includes 'milestones' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME",
          milestones: milestones
        }
      end

      context 'for an array of milestones' do
        let(:milestones) { %w[m1 m2 m3] }

        it_behaves_like 'a valid entry'
      end

      context 'for a single milestone' do
        let(:milestones) { 'm1' }

        it_behaves_like 'a valid entry'
      end
    end

    context "when value includes 'tag_message' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          tag_message: "Annotated tag message"
        }
      end

      it_behaves_like 'a valid entry'
    end

    context "when 'tag_message' is nil" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          tag_message: nil
        }
      end

      it_behaves_like 'a valid entry'
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when value of attribute is invalid' do
          let(:config) { { description: 10 } }

          it_behaves_like 'reports error', 'release description should be a string'
        end

        context 'when release description is missing' do
          let(:config) { { tag_name: 'v0.06' } }

          it_behaves_like 'reports error', "release description can't be blank"
        end

        context 'when release tag_name is missing' do
          let(:config) { { description: "./release_changelog.txt" } }

          it_behaves_like 'reports error', "release tag name can't be blank"
        end

        context 'when there is an unknown key present' do
          let(:config) { { test: 100 } }

          it_behaves_like 'reports error', 'release config contains unknown keys: test'
        end

        context 'when `released_at` is not a valid date' do
          let(:config) { { released_at: 'ABC123' } }

          it_behaves_like 'reports error', 'release released at must be a valid datetime'
        end

        context 'when `ref` is not valid' do
          let(:config) { { ref: 'invalid\branch' } }

          it_behaves_like 'reports error', 'release ref must be a valid ref'
        end

        context 'when `milestones` is not an array of strings' do
          let(:config) { { milestones: [1, 2, 3] } }

          it_behaves_like 'reports error', 'release milestones should be an array of strings or a string'
        end

        context 'when `tag_message` is not a string' do
          let(:config) { { tag_message: 100 } }

          it_behaves_like 'reports error', 'release tag message should be a string'
        end
      end
    end
  end
end

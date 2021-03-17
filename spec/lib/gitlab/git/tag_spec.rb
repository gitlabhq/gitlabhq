# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Tag, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }

  describe '#tags' do
    describe 'first tag' do
      let(:tag) { repository.tags.first }

      it { expect(tag.name).to eq("v1.0.0") }
      it { expect(tag.target).to eq("f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8") }
      it { expect(tag.dereferenced_target.sha).to eq("6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9") }
      it { expect(tag.message).to eq("Release") }
      it { expect(tag.has_signature?).to be_falsey }
      it { expect(tag.signature_type).to eq(:NONE) }
      it { expect(tag.signature).to be_nil }
      it { expect(tag.tagger.name).to eq("Dmitriy Zaporozhets") }
      it { expect(tag.tagger.email).to eq("dmitriy.zaporozhets@gmail.com") }
      it { expect(tag.tagger.date).to eq(Google::Protobuf::Timestamp.new(seconds: 1393491299)) }
      it { expect(tag.tagger.timezone).to eq("+0200") }
    end

    describe 'last tag' do
      let(:tag) { repository.tags.last }

      it { expect(tag.name).to eq("v1.2.1") }
      it { expect(tag.target).to eq("2ac1f24e253e08135507d0830508febaaccf02ee") }
      it { expect(tag.dereferenced_target.sha).to eq("fa1b1e6c004a68b7d8763b86455da9e6b23e36d6") }
      it { expect(tag.message).to eq("Version 1.2.1") }
      it { expect(tag.has_signature?).to be_falsey }
      it { expect(tag.signature_type).to eq(:NONE) }
      it { expect(tag.signature).to be_nil }
      it { expect(tag.tagger.name).to eq("Douwe Maan") }
      it { expect(tag.tagger.email).to eq("douwe@selenight.nl") }
      it { expect(tag.tagger.date).to eq(Google::Protobuf::Timestamp.new(seconds: 1427789449)) }
      it { expect(tag.tagger.timezone).to eq("+0200") }
    end

    describe 'signed tag' do
      let(:project) { create(:project, :repository) }
      let(:tag) { project.repository.find_tag('v1.1.1') }

      it { expect(tag.target).to eq("8f03acbcd11c53d9c9468078f32a2622005a4841") }
      it { expect(tag.dereferenced_target.sha).to eq("189a6c924013fc3fe40d6f1ec1dc20214183bc97") }
      it { expect(tag.message).to eq("x509 signed tag" + "\n" + X509Helpers::User1.signed_tag_signature.chomp) }
      it { expect(tag.has_signature?).to be_truthy }
      it { expect(tag.signature_type).to eq(:X509) }
      it { expect(tag.signature).not_to be_nil }
      it { expect(tag.tagger.name).to eq("Roger Meier") }
      it { expect(tag.tagger.email).to eq("r.meier@siemens.com") }
      it { expect(tag.tagger.date).to eq(Google::Protobuf::Timestamp.new(seconds: 1574261780)) }
      it { expect(tag.tagger.timezone).to eq("+0100") }
    end

    it { expect(repository.tags.size).to eq(SeedRepo::Repo::TAGS.size) }
  end

  describe '.get_message' do
    let(:tag_ids) { %w[f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8 8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b] }

    subject do
      tag_ids.map { |id| described_class.get_message(repository, id) }
    end

    it 'gets tag messages' do
      expect(subject[0]).to eq("Release\n")
      expect(subject[1]).to eq("Version 1.1.0\n")
    end

    it 'gets messages in one batch', :request_store do
      other_repository = double(:repository)
      described_class.get_message(other_repository, tag_ids.first)

      expect { subject.map(&:itself) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
    end
  end

  describe 'tag into from Gitaly tag' do
    context 'message_size != message.size' do
      let(:gitaly_tag) { build(:gitaly_tag, message: ''.b, message_size: message_size) }
      let(:tag) { described_class.new(repository, gitaly_tag) }

      context 'message_size less than threshold' do
        let(:message_size) { 123 }

        it 'fetches tag message separately' do
          expect(described_class).to receive(:get_message).with(repository, gitaly_tag.id)

          tag.message
        end
      end

      context 'message_size greater than threshold' do
        let(:message_size) { described_class::MAX_TAG_MESSAGE_DISPLAY_SIZE + 1 }

        it 'returns a notice about message size' do
          expect(tag.message).to eq("--tag message is too big")
        end
      end
    end
  end

  describe "#cache_key" do
    subject { repository.tags.first }

    it "returns a cache key that changes based on changeable values" do
      expect(subject).to receive(:name).and_return("v1.0.0")
      expect(subject).to receive(:message).and_return("Initial release")

      digest = Digest::SHA1.hexdigest(["v1.0.0", "Initial release", subject.target, subject.target_commit.sha].join)

      expect(subject.cache_key).to eq("tag:#{digest}")
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Tag, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }

  describe '#tags' do
    describe 'unsigned tag' do
      let(:tag) { repository.tags.detect { |t| t.name == 'v1.0.0' } }

      it { expect(tag.name).to eq("v1.0.0") }
      it { expect(tag.target).to eq("f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8") }
      it { expect(tag.dereferenced_target.sha).to eq("6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9") }
      it { expect(tag.message).to eq("Release") }
      it { expect(tag.has_signature?).to be_falsey }
      it { expect(tag.signature_type).to eq(:NONE) }
      it { expect(tag.signature).to be_nil }
      it { expect(tag.user_name).to eq("Dmitriy Zaporozhets") }
      it { expect(tag.user_email).to eq("dmitriy.zaporozhets@gmail.com") }
      it { expect(tag.date).to eq(Time.at(1393491299).utc) }
    end

    describe 'signed tag' do
      let(:tag) { repository.tags.detect { |t| t.name == 'v1.1.1' } }

      it { expect(tag.name).to eq("v1.1.1") }
      it { expect(tag.target).to eq("8f03acbcd11c53d9c9468078f32a2622005a4841") }
      it { expect(tag.dereferenced_target.sha).to eq("189a6c924013fc3fe40d6f1ec1dc20214183bc97") }
      it { expect(tag.message).to eq("x509 signed tag\n" + X509Helpers::User1.signed_tag_signature.chomp) }
      it { expect(tag.has_signature?).to be_truthy }
      it { expect(tag.signature_type).to eq(:X509) }
      it { expect(tag.signature).not_to be_nil }
      it { expect(tag.user_name).to eq("Roger Meier") }
      it { expect(tag.user_email).to eq("r.meier@siemens.com") }
      it { expect(tag.date).to eq(Time.at(1574261780).utc) }
    end

    it { expect(repository.tags.size).to be > 0 }
  end

  describe '.get_message' do
    let(:tag_ids) { %w[f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8 8f03acbcd11c53d9c9468078f32a2622005a4841] }

    subject do
      tag_ids.map { |id| described_class.get_message(repository, id) }
    end

    it 'gets tag messages' do
      expect(subject[0]).to eq("Release\n")
      expect(subject[1]).to eq("x509 signed tag\n" + X509Helpers::User1.signed_tag_signature)
    end

    it 'gets messages in one batch', :request_store do
      other_repository = double(:repository)
      described_class.get_message(other_repository, tag_ids.first)

      expect { subject.map(&:itself) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
    end
  end

  describe '.extract_signature_lazily' do
    let(:project) { create(:project, :repository) }

    subject { described_class.extract_signature_lazily(project.repository, tag_id).itself }

    context 'when the tag is signed' do
      let(:tag_id) { project.repository.find_tag('v1.1.1').id }

      it 'returns signature and signed text' do
        signature, signed_text = subject

        expect(signature).to eq(X509Helpers::User1.signed_tag_signature.chomp)
        expect(signature).to be_a_binary_string
        expect(signed_text).to eq(X509Helpers::User1.signed_tag_base_data)
        expect(signed_text).to be_a_binary_string
      end
    end

    context 'when the tag has no signature' do
      let(:tag_id) { project.repository.find_tag('v1.0.0').id }

      it 'returns empty signature and message as signed text' do
        signature, signed_text = subject

        expect(signature).to be_empty
        expect(signed_text).to eq(X509Helpers::User1.unsigned_tag_base_data)
        expect(signed_text).to be_a_binary_string
      end
    end

    context 'when the tag cannot be found' do
      let(:tag_id) { Gitlab::Git::SHA1_BLANK_SHA }

      it 'raises GRPC::Internal' do
        expect { subject }.to raise_error(GRPC::Internal)
      end
    end

    context 'when the tag ID is invalid' do
      let(:tag_id) { '4b4918a572fa86f9771e5ba40fbd48e' }

      it 'raises GRPC::Internal' do
        expect { subject }.to raise_error(GRPC::Internal)
      end
    end

    context 'when loading signatures in batch once' do
      it 'fetches signatures in batch once' do
        tag_ids = [project.repository.find_tag('v1.1.1').id, project.repository.find_tag('v1.0.0').id]
        signatures = tag_ids.map do |tag_id|
          described_class.extract_signature_lazily(repository, tag_id)
        end

        other_repository = double(:repository)
        described_class.extract_signature_lazily(other_repository, tag_ids.first)

        expect(described_class).to receive(:batch_signature_extraction)
          .with(repository, tag_ids)
          .once
          .and_return({})

        expect(described_class).not_to receive(:batch_signature_extraction)
          .with(other_repository, tag_ids.first)

        2.times { signatures.each(&:itself) }
      end
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

  describe '#date' do
    subject { tag.date }

    let(:tag) { repository.tags.first }

    it 'returns a date' do
      is_expected.to be_present
    end

    context 'when date is missing' do
      before do
        allow(tag).to receive(:tagger).and_return(double(date: nil))
      end

      it 'returns nil' do
        is_expected.to be_nil
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

require 'spec_helper'

describe MergeRequestSerializer do
  let(:user) { build_stubbed(:user) }
  let(:merge_request) { build_stubbed(:merge_request) }

  let(:serializer) do
    described_class.new(current_user: user)
  end

  describe '#represent' do
    let(:opts) { { serializer: serializer_entity } }
    subject { serializer.represent(merge_request, serializer: serializer_entity) }

    context 'when passing basic serializer param' do
      let(:serializer_entity) { 'basic' }

      it 'calls super class #represent with correct params' do
        expect_any_instance_of(BaseSerializer).to receive(:represent)
          .with(merge_request, opts, MergeRequestBasicEntity)

        subject
      end
    end

    context 'when serializer param is falsy' do
      let(:serializer_entity) { nil }

      it 'calls super class #represent with correct params' do
        expect_any_instance_of(BaseSerializer).to receive(:represent)
          .with(merge_request, opts, MergeRequestEntity)

        subject
      end
    end
  end
end

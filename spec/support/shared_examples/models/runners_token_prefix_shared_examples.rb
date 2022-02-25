# frozen_string_literal: true

RSpec.shared_examples 'it has a prefixable runners_token' do |feature_flag|
  context 'feature flag enabled' do
    before do
      stub_feature_flags(feature_flag => [subject])
    end

    describe '#runners_token' do
      it 'has a runners_token_prefix' do
        expect(subject.runners_token_prefix).not_to be_empty
      end

      it 'starts with the runners_token_prefix' do
        expect(subject.runners_token).to start_with(subject.runners_token_prefix)
      end
    end
  end

  context 'feature flag disabled' do
    before do
      stub_feature_flags(feature_flag => false)
    end

    describe '#runners_token' do
      it 'does not have a runners_token_prefix' do
        expect(subject.runners_token_prefix).to be_empty
      end

      it 'starts with the runners_token_prefix' do
        expect(subject.runners_token).to start_with(subject.runners_token_prefix)
      end
    end
  end
end

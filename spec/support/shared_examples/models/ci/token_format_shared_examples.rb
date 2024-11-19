# frozen_string_literal: true

# Expects a `record` variable
RSpec.shared_examples_for 'ensures runners_token is prefixed' do
  describe '#runners_token', feature_category: :system_access do
    let(:runners_prefix) { RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX }

    it 'generates runners_token which starts with runner prefix' do
      expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
    end

    context 'when token is set, but does not match the prefix' do
      before do
        record.set_runners_token('abcdef')
      end

      it 'generates a new token' do
        expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
      end
    end

    context 'when token is set and matches prefix' do
      before do
        record.set_runners_token("#{runners_prefix}-abcdef")
      end

      it 'leaves the token unchanged' do
        expect(record.runners_token).to eq("#{runners_prefix}-abcdef")
      end
    end
  end
end

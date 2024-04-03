# frozen_string_literal: true

RSpec.shared_examples_for 'ensures runners_token is prefixed' do
  describe '#runners_token', feature_category: :system_access do
    let(:runners_prefix) { RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX }

    it 'generates runners_token which starts with runner prefix' do
      expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
    end

    context 'when record has an invalid token' do
      before do
        record.update!(runners_token: invalid_runners_token)
      end

      let(:invalid_runners_token) { "not_start_with_runners_prefix" }

      it 'generates runners_token which starts with runner prefix' do
        expect(record.runners_token).to match(a_string_starting_with(runners_prefix))
      end
    end
  end
end

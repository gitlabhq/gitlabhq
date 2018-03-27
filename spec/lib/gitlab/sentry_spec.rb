require 'spec_helper'

describe Gitlab::Sentry do
  describe '.context' do
    it 'adds the locale to the tags' do
      expect(described_class).to receive(:enabled?).and_return(true)

      described_class.context(nil)

      expect(Raven.tags_context[:locale]).to eq(I18n.locale.to_s)
    end
  end
end

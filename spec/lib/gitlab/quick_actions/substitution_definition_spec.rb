# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::QuickActions::SubstitutionDefinition do
  let(:content) do
    <<EOF
Hello! Let's do this!
/sub_name I like this stuff
/sub_name second substitution
EOF
  end

  subject do
    described_class.new(:sub_name, action_block: proc { |text| "#{text} foo" })
  end

  describe '#perform_substitution!' do
    it 'returns nil if content is nil' do
      expect(subject.perform_substitution(self, nil)).to be_nil
    end

    context 'when content contains command name' do
      it 'performs the substitution by default' do
        expect(subject.perform_substitution(self, content)).to eq <<EOF
Hello! Let's do this!
I like this stuff foo
/sub_name second substitution
EOF
      end
    end

    context 'when content contains command name in word' do
      let(:content) do
        <<EOF
Hello! Let's do this!
`/sub_names` I like this stuff
EOF
      end

      it 'does not perform the substitution' do
        expect(subject.perform_substitution(self, content)).to eq <<EOF
Hello! Let's do this!
`/sub_names` I like this stuff
EOF
      end
    end
  end
end

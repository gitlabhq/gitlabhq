# frozen_string_literal: true

# requires:
#  - `connection` (no-empty, containing `unwanted` and at least one more item)
#  - `unwanted` (single item in collection)
RSpec.shared_examples 'a redactable connection' do
  context 'no redactor set' do
    it 'contains the unwanted item' do
      expect(connection.nodes).to include(unwanted)
    end

    it 'does not redact more than once' do
      connection.nodes
      r_state = connection.send(:redaction_state)

      expect(r_state.redacted { raise 'Should not be called!' }).to be_present
    end

    it_behaves_like 'a connection that counts its nodes'
  end

  let_it_be(:constant_redactor, freeze: false) do
    Class.new do
      def initialize(remove)
        @remove = remove
      end

      def redact(items)
        items - @remove
      end
    end
  end

  context 'redactor is set' do
    let(:redactor) do
      constant_redactor.new([unwanted])
    end

    before do
      connection.redactor = redactor
    end

    it 'does not contain the unwanted item' do
      expect(connection.nodes).not_to include(unwanted)
      expect(connection.nodes).not_to be_empty
    end

    it 'does not redact more than once' do
      expect(redactor).to receive(:redact).once.and_call_original

      connection.nodes
      connection.nodes
      connection.nodes
    end

    it 'counts the nodes left after redaction once' do
      3.times { connection.nodes }

      expect(connection.context.namespace(:gl_logging)[:connection_nodes]).to eq(connection.nodes.size)
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'with sbom licenses' do
  describe '.parse' do
    subject(:license) { described_class.parse({}, is_container_scanning) }

    context 'when it is not a container scanning' do
      let(:is_container_scanning) { false }

      it "creates an instance of #{described_class}" do
        expect(described_class).to receive(:new).and_call_original

        license
      end
    end

    context 'when it is container scanning' do
      let(:is_container_scanning) { true }

      it 'creates an instance of Gitlab::Ci::Parsers::Sbom::License::ContainerScanning' do
        expect(Gitlab::Ci::Parsers::Sbom::License::ContainerScanning).to receive(:new).and_call_original

        license
      end
    end
  end

  describe "#parse" do
    subject(:license) { described_class.new(data).parse }

    context "when the license has neither id nor name" do
      let(:data) do
        {
          "license" => {
            "url" => "https://example.com/license.txt"
          }
        }
      end

      it "returns nil" do
        is_expected.to be_nil
      end
    end

    context "when the license is defined using an expression" do
      let(:data) do
        {
          "expression" => {
            "name" => "EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0"
          }
        }
      end

      it "ignores the license" do
        is_expected.to be_nil
      end
    end
  end
end

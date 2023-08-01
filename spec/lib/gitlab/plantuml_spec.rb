# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Plantuml, feature_category: :shared do
  describe ".configure" do
    subject { described_class.configure }

    let(:plantuml_url) { "http://plantuml.foo.bar" }

    before do
      stub_application_setting(plantuml_url: plantuml_url)
    end

    context "when PlantUML is enabled" do
      before do
        allow(Gitlab::CurrentSettings).to receive(:plantuml_enabled).and_return(true)
      end

      it "configures the endpoint URL" do
        expect(subject.url).to eq(plantuml_url)
      end

      it "enables PNG support" do
        expect(subject.png_enable).to be_truthy
      end

      it "disables SVG support" do
        expect(subject.svg_enable).to be_falsey
      end

      it "disables TXT support" do
        expect(subject.txt_enable).to be_falsey
      end
    end

    context "when PlantUML is disabled" do
      before do
        allow(Gitlab::CurrentSettings).to receive(:plantuml_enabled).and_return(false)
      end

      it "configures the endpoint URL" do
        expect(subject.url).to eq(plantuml_url)
      end

      it "enables PNG support" do
        expect(subject.png_enable).to be_falsey
      end

      it "disables SVG support" do
        expect(subject.svg_enable).to be_falsey
      end

      it "disables TXT support" do
        expect(subject.txt_enable).to be_falsey
      end
    end
  end
end

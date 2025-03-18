# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../../../../tooling/dast_variables/docs/renderer'

RSpec.describe Tooling::DastVariables::Docs::Renderer, feature_category: :dynamic_application_security_testing do
  let(:template) { Rails.root.join('tooling/dast_variables/docs/templates/default.md.haml') }

  describe '#contents' do
    subject(:contents) do
      described_class.new(
        output_file: nil,
        template: template
      ).contents
    end

    describe 'scanner variables table' do
      let(:expectation) do
        <<~DOC
        ## Scanner behavior

        These variables control how the scan is conducted and where its results are stored.

        | CI/CD variable | Type | Example | Description |
        | :------------- | :--- | ------- | :---------- |
        DOC
      end

      it 'renders scanner variables' do
        expect(contents).to include(expectation)
      end
    end

    describe 'site variables table' do
      let(:expectation) do
        <<~DOC
        ## Elements, actions, and timeouts

        These variables tell the scanner where to look for certain elements, which actions to take, and how long to wait for operations to complete.

        | CI/CD variable | Type | Example | Description |
        | :------------- | :--- | ------- | :---------- |
        DOC
      end

      it 'renders site variables' do
        expect(contents).to include(expectation)
      end
    end

    describe 'authentication variables table' do
      let(:expectation) do
        <<~DOC
        ### Authentication

        These variables tell the scanner how to authenticate with your application.

        | CI/CD variable | Type | Example | Description |
        | :------------- | :--- | ------- | :---------- |
        DOC
      end

      it 'renders authentication variables' do
        expect(contents).to include(expectation)
      end
    end

    describe 'links' do
      describe 'CI/CD variables' do
        let(:expectation) do
          <<~DOC
          | `DAST_PKCS12_PASSWORD` | string | `password` | The password of the certificate used in `DAST_PKCS12_CERTIFICATE_BASE64`. Create sensitive [custom CI/CI variables](../../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) using the GitLab UI. |
          DOC
        end

        it 'links to the type definition' do
          expect(contents).to include(expectation)
        end
      end

      describe 'Duration string' do
        let(:expectation) do
          <<~DOC
          | `DAST_ACTIVE_SCAN_TIMEOUT` | [Duration string](https://pkg.go.dev/time#ParseDuration) | `3h` | The maximum amount of time to wait for the active scan phase of the scan to complete. Defaults to 3h. |
          DOC
        end

        it 'links to the type definition' do
          expect(contents).to include(expectation)
        end
      end

      describe 'selector' do
        let(:expectation) do
          <<~DOC
          | `DAST_AUTH_BEFORE_LOGIN_ACTIONS` | [selector](authentication.md#finding-an-elements-selector) | `css:.user,id:show-login-form` | A comma-separated list of selectors representing elements to click on prior to entering the DAST_AUTH_USERNAME and DAST_AUTH_PASSWORD into the login form. |
          DOC
        end

        it 'links to the type definition' do
          expect(contents).to include(expectation)
        end
      end
    end
  end

  describe '#write' do
    let(:output_dir) { Dir.mktmpdir }
    let(:output_file) { File.join(output_dir, 'variables.md') }

    after do
      FileUtils.remove_entry(output_dir)
    end

    it 'writes contents to file' do
      renderer = described_class.new(
        output_file: output_file,
        template: template
      )

      expect(File).to receive(:write).with(output_file, renderer.contents).and_call_original

      renderer.write

      expect(File.exist?(output_file)).to be true
      expect(File.read(output_file)).to eq(renderer.contents)
    end
  end
end

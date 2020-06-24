# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::Parsers::ListV2 do
  let(:valid_file_contents) do
    <<~EOF
    {
      "Next": "",
      "Releases": [
        {
          "Name": "certmanager",
          "Revision": 2,
          "Updated": "Sun Mar 29 06:55:42 2020",
          "Status": "DEPLOYED",
          "Chart": "cert-manager-v0.10.1",
          "AppVersion": "v0.10.1",
          "Namespace": "gitlab-managed-apps"
        },
        {
          "Name": "certmanager-crds",
          "Revision": 2,
          "Updated": "Sun Mar 29 06:55:32 2020",
          "Status": "DEPLOYED",
          "Chart": "cert-manager-crds-v0.2.0",
          "AppVersion": "release-0.10",
          "Namespace": "gitlab-managed-apps"
        },
        {
          "Name": "certmanager-issuer",
          "Revision": 1,
          "Updated": "Tue Feb 18 10:04:04 2020",
          "Status": "FAILED",
          "Chart": "cert-manager-issuer-v0.1.0",
          "AppVersion": "",
          "Namespace": "gitlab-managed-apps"
        },
        {
          "Name": "runner",
          "Revision": 2,
          "Updated": "Sun Mar 29 07:01:01 2020",
          "Status": "DEPLOYED",
          "Chart": "gitlab-runner-0.14.0",
          "AppVersion": "12.8.0",
          "Namespace": "gitlab-managed-apps"
        }
      ]
    }
    EOF
  end

  describe '#initialize' do
    it 'initializes without error' do
      expect do
        described_class.new(valid_file_contents)
      end.not_to raise_error
    end

    it 'raises an error on invalid JSON' do
      expect do
        described_class.new('')
      end.to raise_error(described_class::ParserError)
    end
  end

  describe '#releases' do
    subject(:list_v2) { described_class.new(valid_file_contents) }

    it 'returns list of releases' do
      expect(list_v2.releases).to match([
        a_hash_including('Name' => 'certmanager', 'Status' => 'DEPLOYED'),
        a_hash_including('Name' => 'certmanager-crds', 'Status' => 'DEPLOYED'),
        a_hash_including('Name' => 'certmanager-issuer', 'Status' => 'FAILED'),
        a_hash_including('Name' => 'runner', 'Status' => 'DEPLOYED')
      ])
    end

    context 'empty Releases' do
      let(:valid_file_contents) { '{}' }

      it 'returns an empty array' do
        expect(list_v2.releases).to eq([])
      end
    end

    context 'invalid Releases' do
      let(:invalid_file_contents) do
        '{ "Releases" : ["a", "b"] }'
      end

      subject(:list_v2) { described_class.new(invalid_file_contents) }

      it 'raises an error' do
        expect do
          list_v2.releases
        end.to raise_error(described_class::ParserError, 'Invalid format for Releases')
      end
    end
  end
end

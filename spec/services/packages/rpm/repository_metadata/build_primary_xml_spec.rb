# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::BuildPrimaryXml do
  describe '#execute' do
    subject { described_class.new.execute }

    context "when generate empty xml" do
      let(:expected_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" packages="0"/>
        XML
      end

      it 'generate expected xml' do
        expect(subject).to eq(expected_xml)
      end
    end
  end
end

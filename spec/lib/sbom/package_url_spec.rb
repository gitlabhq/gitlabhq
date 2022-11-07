# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2021 package-url
# Portions Copyright 2022 Gitlab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../support/helpers/next_instance_of'
require_relative '../../support/shared_contexts/lib/sbom/package_url_shared_contexts'

RSpec.describe Sbom::PackageUrl do
  include NextInstanceOf

  let(:args) do
    {
      type: 'example',
      namespace: 'test',
      name: 'test',
      version: '1.0.0',
      qualifiers: { 'arch' => 'x86_64' },
      subpath: 'path/to/package'
    }
  end

  describe '#initialize' do
    subject { described_class.new(**args) }

    context 'with well-formed arguments' do
      it { is_expected.to have_attributes(**args) }
    end

    context 'when no arguments are given' do
      it { expect { described_class.new }.to raise_error(ArgumentError) }
    end

    context 'when required parameters are missing' do
      where(:param) { %i[type name] }

      before do
        args[param] = nil
      end

      with_them do
        it { expect { subject }.to raise_error(ArgumentError) }
      end
    end

    describe 'normalization' do
      it 'downcases provided type component' do
        purl = described_class.new(type: 'EXAMPLE', name: 'test')

        expect(purl.type).to eq('example')
        expect(purl.name).to eq('test')
      end

      it 'does not down provided name component' do
        purl = described_class.new(type: 'example', name: 'TEST')

        expect(purl.type).to eq('example')
        expect(purl.name).to eq('TEST')
      end
    end
  end

  describe '#parse' do
    let(:url) { 'pkg:gem/rails@6.1.6.1' }

    subject(:parse) { described_class.parse(url) }

    it 'delegates parsing to the decoder' do
      expect_next_instance_of(described_class::Decoder, url) do |decoder|
        expect(decoder).to receive(:decode!)
      end

      parse
    end
  end

  describe '#to_h' do
    let(:purl) do
      described_class.new(
        type: type,
        namespace: namespace,
        name: name,
        version: version,
        qualifiers: qualifiers,
        subpath: subpath
      )
    end

    subject(:to_h) { purl.to_h }

    include_context 'with purl matrix'

    with_them do
      it do
        is_expected.to eq(
          {
            scheme: 'pkg',
            type: type,
            namespace: namespace,
            name: name,
            version: version,
            qualifiers: qualifiers,
            subpath: subpath
          }
        )
      end
    end
  end

  describe '#to_s' do
    let(:package) { described_class.new(**args) }

    it 'delegates to_s to the encoder' do
      expect_next_instance_of(described_class::Encoder, package) do |encoder|
        expect(encoder).to receive(:encode)
      end

      package.to_s
    end
  end
end

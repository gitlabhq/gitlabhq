# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'nokogiri'

require_relative '../../scripts/cobertura_splitter'

RSpec.describe CoberturaSplitter, feature_category: :tooling do
  let(:sample_coverage_xml) do
    <<~XML
      <?xml version='1.0'?>
      <!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">
      <coverage line-rate="0.98" lines-covered="1000" lines-valid="1020" complexity="0" version="0" timestamp="1755522175">
        <sources>
          <source>/builds/gitlab-org/gitlab</source>
        </sources>
        <packages>
          <package name="Controllers" line-rate="0.98" complexity="0">
            <classes>
              <class name="ApplicationController" filename="app/controllers/application_controller.rb" line-rate="1.0" complexity="0">
                <methods/>
                <lines>
                  <line number="1" hits="100"/>
                  <line number="2" hits="200"/>
                </lines>
              </class>
            </classes>
          </package>
          <package name="Models" line-rate="0.95" complexity="0">
            <classes>
              <class name="User" filename="app/models/user.rb" line-rate="0.95" complexity="0">
                <methods/>
                <lines>
                  <line number="1" hits="50"/>
                  <line number="2" hits="0"/>
                </lines>
              </class>
            </classes>
          </package>
          <package name="Helpers" line-rate="1.0" complexity="0">
            <classes>
              <class name="ApplicationHelper" filename="app/helpers/application_helper.rb" line-rate="1.0" complexity="0">
                <methods/>
                <lines>
                  <line number="1" hits="25"/>
                </lines>
              </class>
            </classes>
          </package>
        </packages>
      </coverage>
    XML
  end

  let(:temp_file) do
    file = Tempfile.new(['coverage', '.xml'])
    file.write(sample_coverage_xml)
    file.close
    file
  end

  let(:temp_dir) { File.dirname(temp_file.path) }

  subject(:splitter) { described_class.new(temp_file.path) }

  after do
    Dir.glob("#{temp_dir}/coverage-*.xml").each { |f| File.delete(f) } if temp_dir
    temp_file.unlink if temp_file
  end

  describe '#initialize' do
    it 'loads the XML file' do
      expect(splitter.instance_variable_get(:@input_file)).to eq(temp_file.path)
      expect(splitter.instance_variable_get(:@doc)).to be_a(Nokogiri::XML::Document)
    end

    context 'when file does not exist' do
      it 'raises an error' do
        expect { described_class.new('nonexistent.xml') }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '#split' do
    context 'with default max_size_mb' do
      it 'creates one file when packages fit in default size limit' do
        result = splitter.split

        expect(result.size).to eq(1)
        expect(result.first[:package_count]).to eq(3)
      end

      it 'creates output files with correct naming' do
        result = splitter.split

        output_file = result.first[:path]
        expect(File.basename(output_file)).to eq('coverage-0.xml')
        expect(File.exist?(output_file)).to be true
      end

      it 'returns file information' do
        result = splitter.split

        file_info = result.first
        expect(file_info).to have_key(:path)
        expect(file_info).to have_key(:size_mb)
        expect(file_info).to have_key(:package_count)
        expect(file_info[:size_mb]).to be >= 0.0
      end
    end

    context 'with custom max_size_mb' do
      it 'splits into multiple files based on size limit' do
        result = splitter.split(max_size_mb: 0.001)

        expect(result.size).to be >= 2
        result.each do |file_info|
          expect(file_info[:size_mb]).to be <= 0.1
        end
      end

      it 'creates correctly named files' do
        result = splitter.split(max_size_mb: 0.001)

        expect(File.basename(result[0][:path])).to eq('coverage-0.xml')
        expect(File.basename(result[1][:path])).to eq('coverage-1.xml')
      end
    end

    context 'with very small size limit' do
      it 'creates multiple files when size limit is restrictive' do
        result = splitter.split(max_size_mb: 0.001)

        expect(result.size).to be >= 2
        result.each do |file_info|
          expect(file_info[:package_count]).to be >= 1
        end
      end
    end

    describe 'generated XML structure' do
      it 'creates valid XML files' do
        result = splitter.split(max_size_mb: 0.001)

        result.each do |file_info|
          xml_content = File.read(file_info[:path])

          expect(xml_content).to include('<?xml version="1.0" encoding="UTF-8"?>')
          expect(xml_content).to include('<!DOCTYPE coverage SYSTEM')
          expect(xml_content).to include('<coverage')
          expect(xml_content).to include('</coverage>')

          doc = Nokogiri::XML(xml_content)
          expect(doc.errors).to be_empty
        end
      end

      it 'recalculates coverage attributes correctly' do
        result = splitter.split

        xml_content = File.read(result.first[:path])
        doc = Nokogiri::XML(xml_content)
        coverage_node = doc.at_xpath('//coverage')

        expect(coverage_node['line-rate']).to match(/^\d+\.\d+$/)
        expect(coverage_node['lines-covered'].to_i).to be > 0
        expect(coverage_node['lines-valid'].to_i).to be > 0
        expect(coverage_node['timestamp']).to eq('1755522175')
      end

      it 'preserves sources section' do
        result = splitter.split

        xml_content = File.read(result.first[:path])
        doc = Nokogiri::XML(xml_content)
        source_nodes = doc.xpath('//source')

        expect(source_nodes.size).to eq(1)
        expect(source_nodes.first.text).to eq('/builds/gitlab-org/gitlab')
      end

      it 'includes correct packages in each file' do
        result = splitter.split(max_size_mb: 0.001)

        all_packages = result.flat_map do |file_info|
          file_doc = Nokogiri::XML(File.read(file_info[:path]))
          file_doc.xpath('//package/@name').map(&:value)
        end

        expect(all_packages.sort).to eq(%w[Controllers Helpers Models])
      end

      it 'preserves package structure and content' do
        result = splitter.split(max_size_mb: 0.001)

        controllers_file = result.find do |file_info|
          doc = Nokogiri::XML(File.read(file_info[:path]))
          doc.at_xpath('//package[@name="Controllers"]')
        end

        expect(controllers_file).not_to be_nil

        file_doc = Nokogiri::XML(File.read(controllers_file[:path]))
        controller_package = file_doc.at_xpath('//package[@name="Controllers"]')

        expect(controller_package['line-rate']).to eq('0.98')

        classes = controller_package.xpath('.//class')
        expect(classes.size).to eq(1)
        expect(classes.first['name']).to eq('ApplicationController')
        expect(classes.first['filename']).to eq('app/controllers/application_controller.rb')

        lines = classes.first.xpath('.//line')
        expect(lines.size).to eq(2)
        expect(lines.first['number']).to eq('1')
        expect(lines.first['hits']).to eq('100')
      end

      it 'preserves total line counts across split files' do
        result = splitter.split(max_size_mb: 0.001)

        total_covered = result.sum do |file_info|
          doc = Nokogiri::XML(File.read(file_info[:path]))
          doc.root['lines-covered'].to_i
        end

        total_valid = result.sum do |file_info|
          doc = Nokogiri::XML(File.read(file_info[:path]))
          doc.root['lines-valid'].to_i
        end

        expect(total_covered).to eq(4)
        expect(total_valid).to eq(5)
      end
    end

    describe 'edge cases' do
      let(:empty_coverage_xml) do
        <<~XML
          <?xml version='1.0'?>
          <!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">
          <coverage line-rate="0" lines-covered="0" lines-valid="0" complexity="0" version="0" timestamp="0">
            <sources>
              <source>/builds/gitlab-org/gitlab</source>
            </sources>
            <packages>
            </packages>
          </coverage>
        XML
      end

      let(:large_package_xml) do
        large_classes = (1..100).map do |i|
          <<~CLASS
            <class name="LargeClass#{i}" filename="app/models/large_class_#{i}.rb" line-rate="1.0" complexity="0">
              <methods/>
              <lines>
                #{(1..50).map { |line| "<line number=\"#{line}\" hits=\"10\"/>" }.join("\n                ")}
              </lines>
            </class>
          CLASS
        end.join("\n            ")

        <<~XML
          <?xml version='1.0'?>
          <!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">
          <coverage line-rate="0.98" lines-covered="5000" lines-valid="5000" complexity="0" version="0" timestamp="1755522175">
            <sources>
              <source>/builds/gitlab-org/gitlab</source>
            </sources>
            <packages>
              <package name="VeryLargePackage" line-rate="1.0" complexity="0">
                <classes>
                  #{large_classes}
                </classes>
              </package>
            </packages>
          </coverage>
        XML
      end

      let(:empty_temp_file) do
        file = Tempfile.new(['empty_coverage', '.xml'])
        file.write(empty_coverage_xml)
        file.close
        file
      end

      let(:large_package_temp_file) do
        file = Tempfile.new(['large_coverage', '.xml'])
        file.write(large_package_xml)
        file.close
        file
      end

      after do
        empty_temp_file&.unlink
        next unless large_package_temp_file

        Dir.glob("#{File.dirname(large_package_temp_file.path)}/coverage-*.xml").each { |f| File.delete(f) }
        large_package_temp_file.unlink
      end

      it 'handles XML with no packages' do
        empty_splitter = described_class.new(empty_temp_file.path)
        result = empty_splitter.split

        expect(result).to be_empty
      end

      it 'handles very large max_size_mb value' do
        result = splitter.split(max_size_mb: 100)

        expect(result.size).to eq(1)
        expect(result.first[:package_count]).to eq(3)
      end

      it 'respects the size limit strictly for normal cases' do
        result = splitter.split(max_size_mb: 9)

        result.each do |file_info|
          if file_info[:package_count] == 1
            expect(file_info[:size_mb]).to be > 0
          else
            expect(file_info[:size_mb]).to be <= 9.0
          end
        end
      end

      it 'handles packages that individually exceed the size limit' do
        large_splitter = described_class.new(large_package_temp_file.path)
        result = large_splitter.split(max_size_mb: 0.001)

        expect(result.size).to eq(1)
        expect(result.first[:package_count]).to eq(1)
        expect(result.first[:size_mb]).to be > 0.001
      end
    end
  end

  describe '#display_results' do
    it 'displays results summary' do
      result = splitter.split

      expect { splitter.display_results(result) }.to output(/Found packages, created 1 files:/).to_stdout
    end
  end
end

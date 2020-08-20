# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Cobertura do
  describe '#parse!' do
    subject { described_class.new.parse!(cobertura, coverage_report) }

    let(:coverage_report) { Gitlab::Ci::Reports::CoverageReports.new }

    context 'when data is Cobertura style XML' do
      context 'when there is no <class>' do
        let(:cobertura) { '' }

        it 'parses XML and returns empty coverage' do
          expect { subject }.not_to raise_error

          expect(coverage_report.files).to eq({})
        end
      end

      context 'when there is a <sources>' do
        shared_examples_for 'ignoring sources' do
          it 'parses XML without errors' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({})
          end
        end

        context 'and has a single source' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <sources>
              <source>project/src</source>
            </sources>
            EOF
          end

          it_behaves_like 'ignoring sources'
        end

        context 'and has multiple sources' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <sources>
              <source>project/src/foo</source>
              <source>project/src/bar</source>
            </sources>
            EOF
          end

          it_behaves_like 'ignoring sources'
        end
      end

      context 'when there is a single <class>' do
        context 'with no lines' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes><class filename="app.rb"></class></classes>
            EOF
          end

          it 'parses XML and returns empty coverage' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({})
          end
        end

        context 'with a single line' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes>
              <class filename="app.rb"><lines>
                <line number="1" hits="2"/>
              </lines></class>
            </classes>
            EOF
          end

          it 'parses XML and returns a single file with coverage' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2 } })
          end
        end

        context 'with multipe lines and methods info' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="2"/>
                <line number="2" hits="0"/>
              </lines></class>
            </classes>
            EOF
          end

          it 'parses XML and returns a single file with coverage' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0 } })
          end
        end
      end

      context 'when there are multipe <class>' do
        context 'with the same filename and different lines' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="2"/>
                <line number="2" hits="0"/>
              </lines></class>
              <class filename="app.rb"><methods/><lines>
                <line number="6" hits="1"/>
                <line number="7" hits="1"/>
              </lines></class>
            </classes>
            EOF
          end

          it 'parses XML and returns a single file with merged coverage' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0, 6 => 1, 7 => 1 } })
          end
        end

        context 'with the same filename and lines' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <packages><package><classes>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="2"/>
                <line number="2" hits="0"/>
              </lines></class>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="1"/>
                <line number="2" hits="1"/>
              </lines></class>
            </classes></package></packages>
            EOF
          end

          it 'parses XML and returns a single file with summed-up coverage' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 3, 2 => 1 } })
          end
        end

        context 'with missing filename' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="2"/>
                <line number="2" hits="0"/>
              </lines></class>
              <class><methods/><lines>
                <line number="6" hits="1"/>
                <line number="7" hits="1"/>
              </lines></class>
            </classes>
            EOF
          end

          it 'parses XML and ignores class with missing name' do
            expect { subject }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0 } })
          end
        end

        context 'with invalid line information' do
          let(:cobertura) do
            <<-EOF.strip_heredoc
            <classes>
              <class filename="app.rb"><methods/><lines>
                <line number="1" hits="2"/>
                <line number="2" hits="0"/>
              </lines></class>
              <class filename="app.rb"><methods/><lines>
                <line null="test" hits="1"/>
                <line number="7" hits="1"/>
              </lines></class>
            </classes>
            EOF
          end

          it 'raises an error' do
            expect { subject }.to raise_error(described_class::CoberturaParserError)
          end
        end
      end
    end

    context 'when data is not Cobertura style XML' do
      let(:cobertura) { { coverage: '12%' }.to_json }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::CoberturaParserError)
      end
    end
  end
end

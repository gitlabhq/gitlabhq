# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Documents::CoberturaDocument,
  feature_category: :code_testing do
  subject(:parse_report) { Nokogiri::XML::SAX::Parser.new(described_class.new(coverage_report, project_path, paths)).parse(cobertura) }

  describe '#parse!' do
    let(:coverage_report) { Gitlab::Ci::Reports::CoverageReport.new }
    let(:project_path) { 'foo/bar' }
    let(:windows_path) { 'foo\bar' }
    let(:paths) { ['app/user.rb'] }

    let(:cobertura) do
      <<~EOF
        <coverage>
          #{sources_xml}
          #{classes_xml}
        </coverage>
      EOF
    end

    context 'when data is Cobertura style XML' do
      shared_examples_for 'ignoring sources, project_path, and worktree_paths' do
        context 'when there is no <class>' do
          let(:classes_xml) { '' }

          it 'parses XML and returns empty coverage' do
            expect { parse_report }.not_to raise_error

            expect(coverage_report.files).to eq({})
          end
        end

        context 'when there is a single <class>' do
          context 'with no lines' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns empty coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({})
            end
          end

          context 'with a single line' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns a single file with coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2 } })
            end
          end

          context 'without a package parent' do
            let(:classes_xml) do
              <<~EOF
                <packages>
                  <class filename="app.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </packages>
              EOF
            end

            it 'parses XML and returns a single file with coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2 } })
            end
          end

          context 'with multiple lines and methods info' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"><methods/><lines>
                    <line number="1" hits="2"/>
                    <line number="2" hits="0"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns a single file with coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0 } })
            end
          end
        end

        context 'when there are multiple packages' do
          let(:cobertura) do
            <<~EOF
              <coverage>
                <packages><package name="app1"><classes>
                  <class filename="app1.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </classes></package></packages>
                <packages><package name="app2"><classes>
                  <class filename="app2.rb"><lines>
                    <line number="11" hits="3"/>
                  </lines></class>
                </classes></package></packages>
              </coverage>
            EOF
          end

          it 'parses XML and returns coverage information per class' do
            expect { parse_report }.not_to raise_error

            expect(coverage_report.files).to eq({ 'app1.rb' => { 1 => 2 }, 'app2.rb' => { 11 => 3 } })
          end
        end

        context 'when there are multiple <class>' do
          context 'without a package parent' do
            let(:classes_xml) do
              <<~EOF
                <packages>
                  <class filename="app.rb"><methods/><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                  <class filename="foo.rb"><methods/><lines>
                    <line number="6" hits="1"/>
                  </lines></class>
                </packages>
              EOF
            end

            it 'parses XML and returns coverage information per class' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2 }, 'foo.rb' => { 6 => 1 } })
            end
          end

          context 'with the same filename and different lines' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"><methods/><lines>
                    <line number="1" hits="2"/>
                    <line number="2" hits="0"/>
                  </lines></class>
                  <class filename="app.rb"><methods/><lines>
                    <line number="6" hits="1"/>
                    <line number="7" hits="1"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns a single file with merged coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0, 6 => 1, 7 => 1 } })
            end
          end

          context 'with the same filename and lines' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
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
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 3, 2 => 1 } })
            end
          end

          context 'with missing filename' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"><methods/><lines>
                    <line number="1" hits="2"/>
                    <line number="2" hits="0"/>
                  </lines></class>
                  <class><methods/><lines>
                    <line number="6" hits="1"/>
                    <line number="7" hits="1"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and ignores class with missing name' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app.rb' => { 1 => 2, 2 => 0 } })
            end
          end

          context 'with invalid line information' do
            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="app.rb"><methods/><lines>
                    <line number="1" hits="2"/>
                    <line number="2" hits="0"/>
                  </lines></class>
                  <class filename="app.rb"><methods/><lines>
                    <line null="test" hits="1"/>
                    <line number="7" hits="1"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'raises an error' do
              expect { parse_report }.to raise_error(Gitlab::Ci::Parsers::Coverage::Cobertura::InvalidLineInformationError)
            end
          end
        end
      end

      context 'when there is no <sources>' do
        let(:sources_xml) { '' }

        it_behaves_like 'ignoring sources, project_path, and worktree_paths'
      end

      context 'when there is an empty <sources>' do
        let(:sources_xml) { '<sources />' }

        it_behaves_like 'ignoring sources, project_path, and worktree_paths'
      end

      context 'when there is a <sources>' do
        context 'and has a single source with a pattern for Go projects' do
          let(:project_path) { 'local/go' } # Make sure we're not making false positives
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>/usr/local/go/src</source>
              </sources>
            EOF
          end

          it_behaves_like 'ignoring sources, project_path, and worktree_paths'
        end

        context 'and has Windows-style paths' do
          let(:sources_xml) do
            <<~EOF_WIN
              <sources>
                <source>D:\\builds\\#{windows_path}\\app</source>
              </sources>
            EOF_WIN
          end

          context 'when there is a single <class>' do
            context 'with a single line' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><lines>
                      <line number="1" hits="2"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2 } })
              end
            end
          end

          context 'when there is a single <class> with a relative filename' do
            let(:paths) { ['app/subfolder/user.rb'] }

            context 'with a single line' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="subfolder\\user.rb"><lines>
                      <line number="1" hits="2"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/subfolder/user.rb' => { 1 => 2 } })
              end
            end
          end
        end

        context 'and has multiple sources with a pattern for Go projects' do
          let(:project_path) { 'local/go' } # Make sure we're not making false positives
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>/usr/local/go/src</source>
                <source>/go/src</source>
              </sources>
            EOF
          end

          it_behaves_like 'ignoring sources, project_path, and worktree_paths'
        end

        context 'and has a single source but already is at the project root path' do
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>builds/#{project_path}</source>
              </sources>
            EOF
          end

          it_behaves_like 'ignoring sources, project_path, and worktree_paths'
        end

        context 'and has multiple sources but already are at the project root path' do
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>builds/#{project_path}/</source>
                <source>builds/somewhere/#{project_path}</source>
              </sources>
            EOF
          end

          it_behaves_like 'ignoring sources, project_path, and worktree_paths'
        end

        context 'and has a single source that is not at the project root path' do
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>builds/#{project_path}/app</source>
              </sources>
            EOF
          end

          context 'when there is no <class>' do
            let(:classes_xml) { '' }

            it 'parses XML and returns empty coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({})
            end
          end

          context 'when there is a single <class>' do
            context 'with no lines' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns empty coverage' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({})
              end
            end

            context 'with a single line but the filename cannot be determined based on extracted source and worktree paths' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="member.rb"><lines>
                      <line number="1" hits="2"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns empty coverage' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({})
              end
            end

            context 'with a single line' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><lines>
                      <line number="1" hits="2"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2 } })
              end
            end

            context 'with multiple lines and methods info' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2, 2 => 0 } })
              end
            end
          end

          context 'when there are multiple <class>' do
            context 'with the same filename but the filename cannot be determined based on extracted source and worktree paths' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="member.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="member.rb"><methods/><lines>
                      <line number="6" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns empty coverage' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({})
              end
            end

            context 'without a parent package' do
              let(:classes_xml) do
                <<~EOF
                  <packages>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="user.rb"><methods/><lines>
                      <line number="6" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </packages>
                EOF
              end

              it 'parses XML and returns coverage information with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2, 2 => 0, 6 => 1, 7 => 1 } })
              end
            end

            context 'with the same filename and different lines' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="user.rb"><methods/><lines>
                      <line number="6" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with merged coverage, and with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2, 2 => 0, 6 => 1, 7 => 1 } })
              end
            end

            context 'with the same filename and lines' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="1"/>
                      <line number="2" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and returns a single file with summed-up coverage, and with the filename relative to project root' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 3, 2 => 1 } })
              end
            end

            context 'with missing filename' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class><methods/><lines>
                      <line number="6" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and ignores class with missing name' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2, 2 => 0 } })
              end
            end

            context 'with filename that cannot be determined based on extracted source and worktree paths' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="member.rb"><methods/><lines>
                      <line number="6" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'parses XML and ignores class with undetermined filename' do
                expect { parse_report }.not_to raise_error

                expect(coverage_report.files).to eq({ 'app/user.rb' => { 1 => 2, 2 => 0 } })
              end
            end

            context 'with invalid line information' do
              let(:classes_xml) do
                <<~EOF
                  <packages><package name="app"><classes>
                    <class filename="user.rb"><methods/><lines>
                      <line number="1" hits="2"/>
                      <line number="2" hits="0"/>
                    </lines></class>
                    <class filename="user.rb"><methods/><lines>
                      <line null="test" hits="1"/>
                      <line number="7" hits="1"/>
                    </lines></class>
                  </classes></package></packages>
                EOF
              end

              it 'raises an error' do
                expect { parse_report }.to raise_error(Gitlab::Ci::Parsers::Coverage::Cobertura::InvalidLineInformationError)
              end
            end
          end
        end

        context 'and has multiple sources that are not at the project root path' do
          let(:sources_xml) do
            <<~EOF
              <sources>
                <source>builds/#{project_path}/app1/</source>
                <source>builds/#{project_path}/app2/</source>
              </sources>
            EOF
          end

          context 'and a class filename is available under multiple extracted sources' do
            let(:paths) { ['app1/user.rb', 'app2/user.rb'] }

            let(:classes_xml) do
              <<~EOF
                <package name="app1">
                  <classes>
                    <class filename="user.rb"><lines>
                      <line number="1" hits="2"/>
                    </lines></class>
                  </classes>
                </package>
                <package name="app2">
                  <classes>
                    <class filename="user.rb"><lines>
                      <line number="2" hits="3"/>
                    </lines></class>
                  </classes>
                </package>
              EOF
            end

            it 'parses XML and returns the files with the filename relative to project root' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({
                'app1/user.rb' => { 1 => 2 },
                'app2/user.rb' => { 2 => 3 }
              })
            end
          end

          context 'and a class filename is available under one of the extracted sources' do
            let(:paths) { ['app1/member.rb', 'app2/user.rb', 'app2/pet.rb'] }

            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="user.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns a single file with the filename relative to project root using the extracted source where it is first found under' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({ 'app2/user.rb' => { 1 => 2 } })
            end
          end

          context 'and a class filename is not found under any of the extracted sources' do
            let(:paths) { ['app1/member.rb', 'app2/pet.rb'] }

            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="user.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            it 'parses XML and returns empty coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({})
            end
          end

          context 'and a class filename is not found under any of the extracted sources within the iteratable limit' do
            let(:paths) { ['app2/user.rb'] }

            let(:classes_xml) do
              <<~EOF
                <packages><package name="app"><classes>
                  <class filename="record.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                  <class filename="user.rb"><lines>
                    <line number="1" hits="2"/>
                  </lines></class>
                </classes></package></packages>
              EOF
            end

            before do
              stub_const("#{described_class}::MAX_SOURCES", 1)
            end

            it 'parses XML and returns empty coverage' do
              expect { parse_report }.not_to raise_error

              expect(coverage_report.files).to eq({})
            end
          end
        end
      end

      shared_examples_for 'non-smart parsing' do
        let(:sources_xml) do
          <<~EOF
            <sources>
              <source>builds/foo/bar/app</source>
            </sources>
          EOF
        end

        let(:classes_xml) do
          <<~EOF
            <packages><package name="app"><classes>
              <class filename="user.rb"><lines>
                <line number="1" hits="2"/>
              </lines></class>
            </classes></package></packages>
          EOF
        end

        it 'parses XML and returns filenames unchanged just as how they are found in the class node' do
          expect { parse_report }.not_to raise_error

          expect(coverage_report.files).to eq({ 'user.rb' => { 1 => 2 } })
        end
      end

      context 'when project_path is not present' do
        let(:project_path) { nil }
        let(:paths) { ['app/user.rb'] }

        it_behaves_like 'non-smart parsing'
      end

      context 'when worktree_paths is not present' do
        let(:project_path) { 'foo/bar' }
        let(:paths) { nil }

        it_behaves_like 'non-smart parsing'
      end
    end

    context 'when data is not Cobertura style XML' do
      let(:cobertura) { { coverage: '12%' }.to_json }

      it 'raises an error' do
        expect { parse_report }.to raise_error(Gitlab::Ci::Parsers::Coverage::Cobertura::InvalidXMLError)
      end
    end
  end
end

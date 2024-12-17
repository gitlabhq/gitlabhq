# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Common, feature_category: :vulnerability_management do
  describe '#parse!' do
    let_it_be(:scanner_data) do
      {
        scan: {
          scanner: {
            id: "gemnasium",
            name: "Gemnasium",
            version: "2.1.0"
          }
        }
      }
    end

    where(signatures_enabled: [true, false])
    with_them do
      let_it_be(:pipeline) { create(:ci_pipeline) }

      let(:artifact) { build(:ci_job_artifact, :common_security_report) }
      let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago) }
      # The path 'yarn.lock' was initially used by DependencyScanning, it is okay for SAST locations to use it, but this could be made better
      let(:location) { ::Gitlab::Ci::Reports::Security::Locations::Sast.new(file_path: 'yarn.lock', start_line: 1, end_line: 1) }
      let(:tracking_data) { nil }
      let(:vulnerability_flags_data) do
        [
          ::Gitlab::Ci::Reports::Security::Flag.new(type: 'flagged-as-likely-false-positive', origin: 'post analyzer X', description: 'static string to sink'),
          ::Gitlab::Ci::Reports::Security::Flag.new(type: 'flagged-as-likely-false-positive', origin: 'post analyzer Y', description: 'integer to sink')
        ]
      end

      before do
        allow_next_instance_of(described_class) do |parser|
          allow(parser).to receive(:create_location).and_return(location)
          allow(parser).to receive(:tracking_data).and_return(tracking_data)
          allow(parser).to receive(:create_flags).and_return(vulnerability_flags_data)
        end
      end

      describe 'schema validation' do
        let(:validator_class) { Gitlab::Ci::Parsers::Security::Validators::SchemaValidator }
        let(:data) { {}.merge(scanner_data) }
        let(:json_data) { data.to_json }
        let(:parser) { described_class.new(json_data, report, signatures_enabled: signatures_enabled, validate: validate) }

        subject(:parse_report) { parser.parse! }

        before do
          allow(validator_class).to receive(:new).and_call_original
        end

        context 'when the validate flag is set to `false`' do
          let(:validate) { false }

          before do
            allow(parser).to receive_messages(create_scanner: true, create_scan: true)
          end

          it 'does not instantiate the validator' do
            parse_report

            expect(validator_class).not_to have_received(:new).with(
              report.type,
              data.deep_stringify_keys,
              report.version,
              project: pipeline.project,
              scanner: data.dig(:scan, :scanner).deep_stringify_keys
            )
          end

          it 'marks the report as valid' do
            parse_report

            expect(report).not_to be_errored
          end

          it 'keeps the execution flow as normal' do
            parse_report

            expect(parser).to have_received(:create_scanner)
            expect(parser).to have_received(:create_scan)
          end
        end

        context 'when the validate flag is set to `true`' do
          let(:validate) { true }
          let(:valid?) { false }
          let(:errors) { ['foo'] }
          let(:warnings) { ['bar'] }

          before do
            allow_next_instance_of(validator_class) do |instance|
              allow(instance).to receive(:valid?).and_return(valid?)
              allow(instance).to receive(:errors).and_return(errors)
              allow(instance).to receive(:warnings).and_return(warnings)
            end

            allow(parser).to receive_messages(create_scanner: true, create_scan: true)
          end

          it 'instantiates the validator with correct params' do
            parse_report

            expect(validator_class).to have_received(:new).with(
              report.type,
              data.deep_stringify_keys,
              report.version,
              project: pipeline.project,
              scanner: data.dig(:scan, :scanner).deep_stringify_keys
            )
          end

          context 'when the report data is not valid according to the schema' do
            it 'adds errors to the report' do
              expect { parse_report }.to change { report.errors }.from([]).to(
                [
                  { message: 'foo', type: 'Schema' }
                ]
              )
            end

            it 'marks the report as invalid' do
              parse_report

              expect(report).to be_errored
            end

            it 'does not try to create report entities' do
              parse_report

              expect(parser).not_to have_received(:create_scanner)
              expect(parser).not_to have_received(:create_scan)
            end
          end

          context 'when the report data is valid according to the schema' do
            let(:valid?) { true }
            let(:errors) { [] }
            let(:warnings) { [] }

            it 'does not add errors to the report' do
              expect { parse_report }.not_to change { report.errors }.from([])
            end

            context 'and no warnings are present' do
              let(:warnings) { [] }

              it 'does not add warnings to the report' do
                expect { parse_report }.not_to change { report.warnings }.from([])
              end
            end

            context 'and some warnings are present' do
              let(:warnings) { ['bar'] }

              it 'does add warnings to the report' do
                expect { parse_report }.to change { report.warnings }.from([]).to(
                  [
                    { message: 'bar', type: 'Schema' }
                  ]
                )
              end
            end

            it 'keeps the execution flow as normal' do
              parse_report

              expect(parser).to have_received(:create_scanner)
              expect(parser).to have_received(:create_scan)
            end
          end
        end
      end

      context 'report parsing' do
        before do
          artifact.each_blob { |blob| described_class.parse!(blob, report, signatures_enabled: signatures_enabled) }
        end

        describe 'parsing finding.name' do
          let(:artifact) { build(:ci_job_artifact, :common_security_report_with_blank_names) }

          context 'when name is provided' do
            it 'sets name from the report as a name' do
              finding = report.findings.second
              expected_name = Gitlab::Json.parse(finding.raw_metadata)['name']

              expect(finding.name).to eq(expected_name)
            end
          end

          context 'when name is not provided' do
            context 'when location does not exist' do
              let(:location) { nil }

              it 'returns only identifier name' do
                finding = report.findings.third

                expect(finding.name).to eq("CVE-2017-11429")
              end
            end

            context 'when location exists' do
              context 'when CVE identifier exists' do
                it 'combines identifier with location to create name' do
                  finding = report.findings.third

                  expect(finding.name).to eq("CVE-2017-11429 in yarn.lock")
                end
              end

              context 'when CWE identifier exists' do
                it 'combines identifier with location to create name' do
                  finding = report.findings.fourth

                  expect(finding.name).to eq("CWE-2017-11429 in yarn.lock")
                end
              end

              context 'when neither CVE nor CWE identifier exist' do
                it 'combines identifier with location to create name' do
                  finding = report.findings.fifth

                  expect(finding.name).to eq("other-2017-11429 in yarn.lock")
                end
              end
            end
          end
        end

        describe 'parsing finding.details' do
          context 'when details are provided' do
            let(:finding) { report.findings[4] }

            it 'sets details from the report' do
              expected_details = Gitlab::Json.parse(finding.raw_metadata)['details']

              expect(finding.details).to eq(expected_details)
            end
          end

          context 'when details are not provided' do
            let(:finding) { report.findings[5] }

            it 'sets empty hash' do
              expect(finding.details).to eq({})
            end
          end
        end

        describe 'top-level scanner' do
          it 'is the primary scanner' do
            expect(report.primary_scanner.external_id).to eq('gemnasium')
            expect(report.primary_scanner.name).to eq('Gemnasium top-level')
            expect(report.primary_scanner.vendor).to eq('GitLab')
            expect(report.primary_scanner.version).to eq('2.18.0')
          end

          it 'returns nil report has no scanner' do
            empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
            described_class.parse!({}.to_json, empty_report)

            expect(empty_report.primary_scanner).to be_nil
          end
        end

        describe 'parsing scanners' do
          subject(:scanner) { report.findings.first.scanner }

          context 'when the report contains top-level scanner' do
            it 'sets the scanner of finding as top-level scanner' do
              expect(scanner.name).to eq('Gemnasium top-level')
            end
          end

          context 'when the report does not contain top-level scanner' do
            let(:artifact) { build(:ci_job_artifact, :common_security_report_without_top_level_scanner) }

            it 'sets the scanner of finding as `vulnerabilities[].scanner`' do
              expect(scanner.name).to eq('Gemnasium')
            end
          end
        end

        describe 'parsing scan' do
          it 'returns scan object for each finding' do
            scans = report.findings.map(&:scan)

            expect(scans.map(&:status).all?('success')).to be(true)
            expect(scans.map(&:start_time).all?('2022-08-10T21:37:00')).to be(true)
            expect(scans.map(&:end_time).all?('2022-08-10T21:38:00')).to be(true)
            expect(scans.size).to eq(7)
            expect(scans.first).to be_a(::Gitlab::Ci::Reports::Security::Scan)
          end

          it 'returns nil when scan is not a hash' do
            empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
            described_class.parse!({}.to_json, empty_report)

            expect(empty_report.scan).to be(nil)
          end
        end

        describe 'parsing schema version' do
          it 'parses the version' do
            expect(report.version).to eq('14.0.2')
          end

          it 'returns nil when there is no version' do
            empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
            described_class.parse!({}.to_json, empty_report)

            expect(empty_report.version).to be_nil
          end
        end

        describe 'parsing analyzer' do
          it 'associates analyzer with report' do
            expect(report.analyzer.id).to eq('common-analyzer')
            expect(report.analyzer.name).to eq('Common Analyzer')
            expect(report.analyzer.version).to eq('2.0.1')
            expect(report.analyzer.vendor).to eq('Common')
          end

          it 'returns nil when analyzer data is not available' do
            empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
            described_class.parse!({}.to_json, empty_report)

            expect(empty_report.analyzer).to be_nil
          end
        end

        describe 'parsing flags' do
          it 'returns flags object for each finding' do
            flags = report.findings.first.flags

            expect(flags).to contain_exactly(
              have_attributes(type: 'flagged-as-likely-false-positive', origin: 'post analyzer X', description: 'static string to sink'),
              have_attributes(type: 'flagged-as-likely-false-positive', origin: 'post analyzer Y', description: 'integer to sink')
            )
          end
        end

        describe 'parsing links' do
          it 'returns links object for each finding', :aggregate_failures do
            links = report.findings.flat_map(&:links)

            expect(links.map(&:url)).to match_array(['https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1020', 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1030',
                                                     "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-2137", "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-2138",
                                                     "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-2139", "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-2140"])
            expect(links.map(&:name)).to match_array([nil, nil, nil, nil, nil, 'CVE-1030'])
            expect(links.size).to eq(6)
            expect(links.first).to be_a(::Gitlab::Ci::Reports::Security::Link)
          end
        end

        describe 'parsing evidence' do
          RSpec::Matchers.define_negated_matcher :have_values, :be_empty

          it 'returns evidence object for each finding', :aggregate_failures do
            all_evidences = report.findings.map(&:evidence)
            evidences = all_evidences.compact
            data = evidences.map(&:data)
            summaries = evidences.map { |e| e.data["summary"] }

            expect(all_evidences.size).to eq(7)
            expect(evidences.size).to eq(2)
            expect(evidences).to all(be_a(::Gitlab::Ci::Reports::Security::Evidence))
            expect(data).to all(have_values)
            expect(summaries).to all(match(/The Origin header was changed/))
          end
        end

        describe 'setting CVSS' do
          let(:cvss_vectors) { report.findings.filter_map(&:cvss).reject(&:empty?) }

          it 'ingests the provided CVSS vectors' do
            expect(cvss_vectors.count).to eq(1)
          end
        end

        describe 'setting the uuid' do
          let(:finding_uuids) { report.findings.map(&:uuid) }
          let(:uuid_1) do
            Security::VulnerabilityUUID.generate(
              report_type: "sast",
              primary_identifier_fingerprint: report.findings[0].identifiers.first.fingerprint,
              location_fingerprint: location.fingerprint,
              project_id: pipeline.project_id
            )
          end

          let(:uuid_2) do
            Security::VulnerabilityUUID.generate(
              report_type: "sast",
              primary_identifier_fingerprint: report.findings[1].identifiers.first.fingerprint,
              location_fingerprint: location.fingerprint,
              project_id: pipeline.project_id
            )
          end

          let(:expected_uuids) { [uuid_1, uuid_2, nil] }

          it 'sets the UUIDv5 for findings', :aggregate_failures do
            allow_next_instance_of(Gitlab::Ci::Reports::Security::Report) do |report|
              allow(report).to receive(:type).and_return('sast')

              expect(finding_uuids).to match_array(expected_uuids)
            end
          end
        end

        describe 'setting the `found_by_pipeline` attribute' do
          subject { report.findings.map(&:found_by_pipeline).uniq }

          it { is_expected.to eq([pipeline]) }
        end

        describe 'parsing tracking' do
          let(:finding) { report.findings.first }

          context 'with invalid tracking information' do
            let(:tracking_data) do
              {
                'type' => 'source',
                'items' => [
                  'signatures' => [
                    { 'algorithm' => 'hash', 'value' => 'hash_value' },
                    { 'algorithm' => 'location', 'value' => 'location_value' },
                    { 'algorithm' => 'INVALID', 'value' => 'scope_offset_value' }
                  ]
                ]
              }
            end

            it 'ignores invalid algorithm types' do
              expect(finding.signatures.size).to eq(2)
              expect(finding.signatures.map(&:algorithm_type).to_set).to eq(Set['hash', 'location'])
            end
          end

          context 'with valid tracking information' do
            let(:tracking_data) do
              {
                'type' => 'source',
                'items' => [
                  'signatures' => [
                    { 'algorithm' => 'hash', 'value' => 'hash_value' },
                    { 'algorithm' => 'location', 'value' => 'location_value' },
                    { 'algorithm' => 'scope_offset', 'value' => 'scope_offset_value' }
                  ]
                ]
              }
            end

            it 'creates signatures for each signature algorithm' do
              expect(finding.signatures.size).to eq(3)
              expect(finding.signatures.map(&:algorithm_type)).to eq(%w[hash location scope_offset])

              signatures = finding.signatures.index_by(&:algorithm_type)
              expected_values = tracking_data['items'][0]['signatures'].index_by { |x| x['algorithm'] }
              expect(signatures['hash'].signature_value).to eq(expected_values['hash']['value'])
              expect(signatures['location'].signature_value).to eq(expected_values['location']['value'])
              expect(signatures['scope_offset'].signature_value).to eq(expected_values['scope_offset']['value'])
            end

            it 'sets the uuid according to the higest priority signature' do
              highest_signature = finding.signatures.max_by(&:priority)

              identifiers = if signatures_enabled
                              "#{finding.report_type}-#{finding.primary_identifier.fingerprint}-#{highest_signature.signature_hex}-#{report.project_id}"
                            else
                              "#{finding.report_type}-#{finding.primary_identifier.fingerprint}-#{finding.location.fingerprint}-#{report.project_id}"
                            end

              expect(finding.uuid).to eq(Gitlab::UUID.v5(identifiers))
            end
          end
        end

        describe 'handling the unicode null characters' do
          let(:artifact) { build(:ci_job_artifact, :common_security_report_with_unicode_null_character) }

          it 'escapes the unicode null characters while parsing the report' do
            finding = report.findings.first

            expect(finding.solution).to eq('Upgrade to latest version.\u0000')
          end

          it 'does not introduce a Unicode null character while trying to escape an already escaped null character' do
            finding = report.findings.first

            expect(finding.description).to eq('This string does not contain a Unicode null character \\\\u0000')
          end

          it 'adds warning to report' do
            expect(report.warnings).to include({ type: 'Parsing', message: 'Report artifact contained unicode null characters which are escaped during the ingestion.' })
          end
        end
      end
    end
  end
end

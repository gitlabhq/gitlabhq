# frozen_string_literal: true

module MigrationHelpers
  module VulnerabilitiesHelper
    # rubocop:disable Metrics/ParameterLists
    def create_finding!(
      project_id:, scanner_id:, primary_identifier_id:, vulnerability_id: nil,
      name: "test", severity: 7, report_type: 0,
      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
      metadata_version: 'test', raw_metadata: 'test', uuid: 'b1cee17e-3d7a-11ed-b878-0242ac120002')
      table(:vulnerability_occurrences).create!(
        vulnerability_id: vulnerability_id,
        project_id: project_id,
        name: name,
        severity: severity,
        report_type: report_type,
        project_fingerprint: project_fingerprint,
        scanner_id: scanner_id,
        primary_identifier_id: primary_identifier_id,
        location_fingerprint: location_fingerprint,
        metadata_version: metadata_version,
        raw_metadata: raw_metadata,
        uuid: uuid
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def create_vulnerability!(
      project_id:, author_id:, finding_id:, title: 'test', severity: 7, report_type: 0)
      table(:vulnerabilities).create!(
        project_id: project_id,
        author_id: author_id,
        title: title,
        severity: severity,
        confidence: confidence,
        report_type: report_type,
        finding_id: finding_id
      )
    end
  end
end

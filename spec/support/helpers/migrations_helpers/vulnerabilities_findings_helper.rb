# frozen_string_literal: true

module MigrationHelpers
  module VulnerabilitiesFindingsHelper
    def attributes_for_vulnerabilities_finding
      uuid = SecureRandom.uuid

      {
        project_fingerprint: SecureRandom.hex(20),
        location_fingerprint: Digest::SHA1.hexdigest(SecureRandom.hex(10)), # rubocop:disable Fips/SHA1
        uuid: uuid,
        name: "Vulnerability Finding #{uuid}",
        metadata_version: '1.3',
        raw_metadata: raw_metadata
      }
    end

    def raw_metadata
      {
        "description" => "The cipher does not provide data integrity update 1",
        "message" => "The cipher does not provide data integrity",
        "cve" => "818bf5dacb291e15d9e6dc3c5ac32178:CIPHER",
        "solution" => "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
        "location" => {
          "file" => "maven/src/main/java/com/gitlab/security_products/tests/App.java",
          "start_line" => 29,
          "end_line" => 29,
          "class" => "com.gitlab.security_products.tests.App",
          "method" => "insecureCypher"
        },
        "links" => [
          {
            "name" => "Cipher does not check for integrity first?",
            "url" => "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first"
          }
        ],
        "assets" => [
          {
            "type" => "postman",
            "name" => "Test Postman Collection",
            "url" => "http://localhost/test.collection"
          }
        ],
        "evidence" => {
          "summary" => "Credit card detected",
          "request" => {
            "method" => "GET",
            "url" => "http://goat:8080/WebGoat/logout",
            "body" => nil,
            "headers" => [
              {
                "name" => "Accept",
                "value" => "*/*"
              }
            ]
          },
          "response" => {
            "reason_phrase" => "OK",
            "status_code" => 200,
            "body" => nil,
            "headers" => [
              {
                "name" => "Content-Length",
                "value" => "0"
              }
            ]
          },
          "source" => {
            "id" => "assert:Response Body Analysis",
            "name" => "Response Body Analysis",
            "url" => "htpp://hostname/documentation"
          },
          "supporting_messages" => [
            {
              "name" => "Origional",
              "request" => {
                "method" => "GET",
                "url" => "http://goat:8080/WebGoat/logout",
                "body" => "",
                "headers" => [
                  {
                    "name" => "Accept",
                    "value" => "*/*"
                  }
                ]
              }
            },
            {
              "name" => "Recorded",
              "request" => {
                "method" => "GET",
                "url" => "http://goat:8080/WebGoat/logout",
                "body" => "",
                "headers" => [
                  {
                    "name" => "Accept",
                    "value" => "*/*"
                  }
                ]
              },
              "response" => {
                "reason_phrase" => "OK",
                "status_code" => 200,
                "body" => "",
                "headers" => [
                  {
                    "name" => "Content-Length",
                    "value" => "0"
                  }
                ]
              }
            }
          ]
        }
      }
    end
  end
end

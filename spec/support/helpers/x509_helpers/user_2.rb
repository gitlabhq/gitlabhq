# frozen_string_literal: true

module X509Helpers
  module User2
    extend self

    def commit
      '440bf5b2b499a90d9adcbebe3752f8c6f245a1aa'
    end

    def path
      'gitlab-test'
    end

    def trust_cert
      <<~TRUSTCERTIFICATE
        -----BEGIN CERTIFICATE-----
        MIICGjCCAaGgAwIBAgIUALnViVfnU0brJasmRkHrn/UnfaQwCgYIKoZIzj0EAwMw
        KjEVMBMGA1UEChMMc2lnc3RvcmUuZGV2MREwDwYDVQQDEwhzaWdzdG9yZTAeFw0y
        MjA0MTMyMDA2MTVaFw0zMTEwMDUxMzU2NThaMDcxFTATBgNVBAoTDHNpZ3N0b3Jl
        LmRldjEeMBwGA1UEAxMVc2lnc3RvcmUtaW50ZXJtZWRpYXRlMHYwEAYHKoZIzj0C
        AQYFK4EEACIDYgAE8RVS/ysH+NOvuDZyPIZtilgUF9NlarYpAd9HP1vBBH1U5CV7
        7LSS7s0ZiH4nE7Hv7ptS6LvvR/STk798LVgMzLlJ4HeIfF3tHSaexLcYpSASr1kS
        0N/RgBJz/9jWCiXno3sweTAOBgNVHQ8BAf8EBAMCAQYwEwYDVR0lBAwwCgYIKwYB
        BQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU39Ppz1YkEZb5qNjp
        KFWixi4YZD8wHwYDVR0jBBgwFoAUWMAeX5FFpWapesyQoZMi0CrFxfowCgYIKoZI
        zj0EAwMDZwAwZAIwPCsQK4DYiZYDPIaDi5HFKnfxXx6ASSVmERfsynYBiX2X6SJR
        nZU84/9DZdnFvvxmAjBOt6QpBlc4J/0DxvkTCqpclvziL6BCCPnjdlIB3Pu3BxsP
        mygUY7Ii2zbdCdliiow=
        -----END CERTIFICATE-----
      TRUSTCERTIFICATE
    end

    def signed_commit_signature
      <<~SIGNATURE
      -----BEGIN SIGNED MESSAGE-----
      MIIEOQYJKoZIhvcNAQcCoIIEKjCCBCYCAQExDTALBglghkgBZQMEAgEwCwYJKoZI
      hvcNAQcBoIIC2jCCAtYwggJdoAMCAQICFC5R9EXk+ljFhyCs4urRxmCuvQNAMAoG
      CCqGSM49BAMDMDcxFTATBgNVBAoTDHNpZ3N0b3JlLmRldjEeMBwGA1UEAxMVc2ln
      c3RvcmUtaW50ZXJtZWRpYXRlMB4XDTIzMDgxOTE3NTgwNVoXDTIzMDgxOTE4MDgw
      NVowADBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBGajWb10Rt36IMxtJmjRDa7
      5O6YCLhVq9+LNJSAx2M7p6netqW7W+lwym4z1Y1gXLdGHBshrbx/yr6Trhh2TCej
      ggF8MIIBeDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYD
      VR0OBBYEFBttEjGzNppCqA4tlZY4oaxkdmQbMB8GA1UdIwQYMBaAFN/T6c9WJBGW
      +ajY6ShVosYuGGQ/MCUGA1UdEQEB/wQbMBmBF2dpdGxhYmdwZ3Rlc3RAZ21haWwu
      Y29tMCwGCisGAQQBg78wAQEEHmh0dHBzOi8vZ2l0aHViLmNvbS9sb2dpbi9vYXV0
      aDAuBgorBgEEAYO/MAEIBCAMHmh0dHBzOi8vZ2l0aHViLmNvbS9sb2dpbi9vYXV0
      aDCBiwYKKwYBBAHWeQIEAgR9BHsAeQB3AN09MGrGxxEyYxkeHJlnNwKiSl643jyt
      /4eKcoAvKe6OAAABig7ydOsAAAQDAEgwRgIhAMqJnFLAspeqfbK/gA/7zjceyExq
      QN7qDXWKRLS01rTvAiEAp/uBShQb9tVa3P3fYVAMiXydvr5dqCpNiuudZiuYq0Yw
      CgYIKoZIzj0EAwMDZwAwZAIwWKXYyP5FvbfhvfLkV0tN887ax1eg7TmF1Tzkugag
      cLJ5MzK3xYNcUO/3AxO3H/b8AjBD9DF6R4kFO4cXoqnpsk2FTUeSPiUJ+0x2PDFG
      gQZvoMWz7CnwjXml8XDEKNpYoPkxggElMIIBIQIBATBPMDcxFTATBgNVBAoTDHNp
      Z3N0b3JlLmRldjEeMBwGA1UEAxMVc2lnc3RvcmUtaW50ZXJtZWRpYXRlAhQuUfRF
      5PpYxYcgrOLq0cZgrr0DQDALBglghkgBZQMEAgGgaTAYBgkqhkiG9w0BCQMxCwYJ
      KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzA4MTkxNzU4MDVaMC8GCSqGSIb3
      DQEJBDEiBCB4B7DeGk22WmBseJzjjRJcQsyYxu0PNDAFXq55uJ7MSzAKBggqhkjO
      PQQDAgRHMEUCIQCNegIrK6m1xyGuu4lw06l22VQsmO74/k3H236jCFF+bAIgAX1N
      rxBFWnjWboZmAV1NuduTD/YToShK6iRmJ/NpILA=
      -----END SIGNED MESSAGE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
      tree 7d5ee08cadaa161d731c56a9265feef130143b07
      parent 4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6
      author Mona Lisa <gitlabgpgtest@gmail.com> 1692467872 +0000
      committer Mona Lisa <gitlabgpgtest@gmail.com> 1692467872 +0000

      Sigstore Signed Commit
      SIGNEDDATA
    end

    def signed_commit_time
      Time.at(1692467872)
    end

    def signed_tag_time
      Time.at(1692467872)
    end

    def signed_tag_signature
      <<~SIGNATURE
      -----BEGIN SIGNED MESSAGE-----
      MIIEOgYJKoZIhvcNAQcCoIIEKzCCBCcCAQExDTALBglghkgBZQMEAgEwCwYJKoZI
      hvcNAQcBoIIC2zCCAtcwggJdoAMCAQICFB5qFHBSNfcJDZecnHK5/tleuX3yMAoG
      CCqGSM49BAMDMDcxFTATBgNVBAoTDHNpZ3N0b3JlLmRldjEeMBwGA1UEAxMVc2ln
      c3RvcmUtaW50ZXJtZWRpYXRlMB4XDTIzMDgxOTE3NTgzM1oXDTIzMDgxOTE4MDgz
      M1owADBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABKJtbdL88PM8lE21CuyDYlZm
      0xZYCThoXZSGmULrgE5+hfroCIbLswOi5i6TyB8j4CCe0Jxeu94Jn+76SXF+lbej
      ggF8MIIBeDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYD
      VR0OBBYEFBkU3IBENVJYeyK9b56vbGGrjPwYMB8GA1UdIwQYMBaAFN/T6c9WJBGW
      +ajY6ShVosYuGGQ/MCUGA1UdEQEB/wQbMBmBF2dpdGxhYmdwZ3Rlc3RAZ21haWwu
      Y29tMCwGCisGAQQBg78wAQEEHmh0dHBzOi8vZ2l0aHViLmNvbS9sb2dpbi9vYXV0
      aDAuBgorBgEEAYO/MAEIBCAMHmh0dHBzOi8vZ2l0aHViLmNvbS9sb2dpbi9vYXV0
      aDCBiwYKKwYBBAHWeQIEAgR9BHsAeQB3AN09MGrGxxEyYxkeHJlnNwKiSl643jyt
      /4eKcoAvKe6OAAABig7y4tYAAAQDAEgwRgIhAMUjWh8ayhjWDI3faFah3Du/7IuY
      xzbUXaPQnCyUbvwwAiEAwHgWv8fmKMudbVu37Nbq/c1cdnQqDK9Y2UGtlmzaLrYw
      CgYIKoZIzj0EAwMDaAAwZQIwZTKZlS4HNJH48km3pxG95JTbldSBhvFlrpIEVRUd
      TEK6uGQJmpIm1WYQjbJbiVS8AjEA+2NoAdMuRpa2k13HUfWQEMtzQcxZMMNB7Yux
      9ZIADOlFp701ujtFSZAXgqGL3FYKMYIBJTCCASECAQEwTzA3MRUwEwYDVQQKEwxz
      aWdzdG9yZS5kZXYxHjAcBgNVBAMTFXNpZ3N0b3JlLWludGVybWVkaWF0ZQIUHmoU
      cFI19wkNl5yccrn+2V65ffIwCwYJYIZIAWUDBAIBoGkwGAYJKoZIhvcNAQkDMQsG
      CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjMwODE5MTc1ODMzWjAvBgkqhkiG
      9w0BCQQxIgQgwpYCAlbS6KnfgxQD3SATWUbdUssLaBWkHwTkmtCye4wwCgYIKoZI
      zj0EAwIERzBFAiB8y5bGhWJvWCHQyma7oF038ZPLzXmsDJyJffJHoAb6XAIhAOW3
      gxuYuJAKP86B1fY0vYCZHF8vU6SZAcE6teSDowwq
      -----END SIGNED MESSAGE-----
      SIGNATURE
    end

    def signed_tag_base_data
      <<~SIGNEDDATA
      object 440bf5b2b499a90d9adcbebe3752f8c6f245a1aa
      type commit
      tag v1.1.2
      tagger Mona Lisa <gitlabgpgtest@gmail.com> 1692467901 +0000

      Sigstore Signed Tag
      SIGNEDDATA
    end

    def certificate_serial
      264441215000592123389532407734419590292801651520
    end

    def tag_certificate_serial
      173635382582380059990335547381753891120957980146
    end

    def certificate_subject_key_identifier
      '1B:6D:12:31:B3:36:9A:42:A8:0E:2D:95:96:38:A1:AC:64:76:64:1B'
    end

    def tag_certificate_subject_key_identifier
      '19:14:DC:80:44:35:52:58:7B:22:BD:6F:9E:AF:6C:61:AB:8C:FC:18'
    end

    def issuer_subject_key_identifier
      'DF:D3:E9:CF:56:24:11:96:F9:A8:D8:E9:28:55:A2:C6:2E:18:64:3F'
    end

    def tag_issuer_subject_key_identifier
      'DF:D3:E9:CF:56:24:11:96:F9:A8:D8:E9:28:55:A2:C6:2E:18:64:3F'
    end

    def certificate_email
      'gitlabgpgtest@gmail.com'
    end

    def tag_email
      'gitlabgpgtest@gmail.com'
    end

    def certificate_issuer
      'CN=sigstore-intermediate,O=sigstore.dev'
    end

    def tag_certificate_issuer
      'CN=sigstore-intermediate,O=sigstore.dev'
    end

    def certificate_subject
      ''
    end

    def names
      ['Mona Lisa']
    end

    def emails
      ['gitlabgpgtest@gmail.com']
    end
  end
end

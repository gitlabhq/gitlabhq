# frozen_string_literal: true

module X509Helpers
  module User1
    extend self

    def commit
      'a4df3c87f040f5fa693d4d55a89b6af74e22cb56'
    end

    def path
      'gitlab-test'
    end

    def trust_cert
      <<~TRUSTCERTIFICATE
        -----BEGIN CERTIFICATE-----
        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
        -----END CERTIFICATE-----
      TRUSTCERTIFICATE
    end

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN SIGNED MESSAGE-----
        MIISUgYJKoZIhvcNAQcCoIISQzCCEj8CAQExDTALBglghkgBZQMEAgEwCwYJKoZI
        hvcNAQcBoIIP3TCCB2kwggVRoAMCAQICBGvn1/4wDQYJKoZIhvcNAQELBQAwgZ8x
        CzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCYXllcm4xETAPBgNVBAcMCE11ZW5jaGVu
        MRAwDgYDVQQKDAdTaWVtZW5zMREwDwYDVQQFEwhaWlpaWlpBMjEdMBsGA1UECwwU
        U2llbWVucyBUcnVzdCBDZW50ZXIxKDAmBgNVBAMMH1NpZW1lbnMgSXNzdWluZyBD
        QSBFRSBBdXRoIDIwMTYwHhcNMTcwMjAzMDY1MzUyWhcNMjAwMjAzMDY1MzUyWjBb
        MREwDwYDVQQFEwhaMDAwTldESDEOMAwGA1UEKgwFUm9nZXIxDjAMBgNVBAQMBU1l
        aWVyMRAwDgYDVQQKDAdTaWVtZW5zMRQwEgYDVQQDDAtNZWllciBSb2dlcjCCASIw
        DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIpqbpRAtn+vetgVb+APuoVOytZx
        TmfWovp22nsmJQwE8ZgrJihRjIez0wjD3cvSREvWUXsvbiyxrSHmmwycRCV9YGi1
        Y9vaYRKOrWhT64Xv6wq6oq8VoA5J3z6V5P6Tkj7g9Q3OskRuSbhFQY89VUdsea+N
        mcv/XrwtQR0SekfSZw9k0LhbauE69SWRV26O03raengjecbbkS+GTlP30/CqPzzQ
        4Ac2TmmVF7RlkGRB05mJqHS+nDK7Lmcr7jD0e92YW+v8Lft4Qu3MpFTYVa7zk712
        5xWAgedyOaJb6TpJEz8KRX8v3i0PilQnuKAqZFkLjNcydOox0AtYRW1P2iMCAwEA
        AaOCAu4wggLqMB0GA1UdDgQWBBTsALUoAlzTpaGrwqE0gYSqv5vP+DBDBgNVHREE
        PDA6oCMGCisGAQQBgjcUAgOgFQwTci5tZWllckBzaWVtZW5zLmNvbYETci5tZWll
        ckBzaWVtZW5zLmNvbTAOBgNVHQ8BAf8EBAMCB4AwKQYDVR0lBCIwIAYIKwYBBQUH
        AwIGCCsGAQUFBwMEBgorBgEEAYI3FAICMIHKBgNVHR8EgcIwgb8wgbyggbmggbaG
        Jmh0dHA6Ly9jaC5zaWVtZW5zLmNvbS9wa2k/WlpaWlpaQTIuY3JshkFsZGFwOi8v
        Y2wuc2llbWVucy5uZXQvQ049WlpaWlpaQTIsTD1QS0k/Y2VydGlmaWNhdGVSZXZv
        Y2F0aW9uTGlzdIZJbGRhcDovL2NsLnNpZW1lbnMuY29tL0NOPVpaWlpaWkEyLG89
        VHJ1c3RjZW50ZXI/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdDBFBgNVHSAEPjA8
        MDoGDSsGAQQBoWkHAgIDAQEwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3dy5zaWVt
        ZW5zLmNvbS9wa2kvMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUvb0qQyI9SEpX
        fpgxF6lwne6fqJkwggEEBggrBgEFBQcBAQSB9zCB9DAyBggrBgEFBQcwAoYmaHR0
        cDovL2FoLnNpZW1lbnMuY29tL3BraT9aWlpaWlpBMi5jcnQwQQYIKwYBBQUHMAKG
        NWxkYXA6Ly9hbC5zaWVtZW5zLm5ldC9DTj1aWlpaWlpBMixMPVBLST9jQUNlcnRp
        ZmljYXRlMEkGCCsGAQUFBzAChj1sZGFwOi8vYWwuc2llbWVucy5jb20vQ049Wlpa
        WlpaQTIsbz1UcnVzdGNlbnRlcj9jQUNlcnRpZmljYXRlMDAGCCsGAQUFBzABhiRo
        dHRwOi8vb2NzcC5wa2ktc2VydmljZXMuc2llbWVucy5jb20wDQYJKoZIhvcNAQEL
        BQADggIBAFY2sbX8DKjKlp0OdH+7Ak21ZdRr6p6JIXzQShWpuFr3wYTpM47+WYVe
        arBekf8eS08feM+TWw6FHt/VNMpn5fLr20jHn7h+j3ClerAxQbx8J6BxhwJ/4DMy
        0cCdbe/fpfJyD/8TGdjnxwAgoq9iPuy1ueVnevygnLcuq1+se6EWJm9v1zrwB0LH
        rE4/NaSCi06+KGg0D9yiigma9yErRZCiaFvqYXUEl7iGpu2OM9o38gZfGzkKaPtQ
        e9BzRs6ndmvNpQQGLXvOlHn6DIsOuBHJp66A+wumRO2AC8rs1rc4NAIjCFRrz8k1
        kzb+ibFiTklWG69+At5/nb06BO/0ER4U18sSpmvOsFKNKPXzLkAn8O8ZzB+8afxy
        egiIJFxYaqoJcQq3CCv8Xp7tp6I+ojr1ui0jK0yqJq6QfgS8FCXIJ+EErNYuoerx
        ba6amD83e524sdMhCfD5dw6IeEY7LUl465ifUm+v5W3jStfa+0cQXnLZNGsC85nP
        Lw5cXVIE3LfoSO3kWH45MfcX32fuqmyP2N3k+/+IOfUpSdT1iR1pEu0g/mow7lGj
        CZngjmMpoto/Qi3l/n1KPWfmB09FZlUhHcGsHbK8+mrkqpv6HW3tKDSorah98aLM
        Wvu1IXTrU9fOyBqt92i0e5buH+/9NHia0i6k79kwQy5wu6Q21GgUMIIIbDCCBlSg
        AwIBAgIEL4jNizANBgkqhkiG9w0BAQsFADCBmTELMAkGA1UEBhMCREUxDzANBgNV
        BAgMBkJheWVybjERMA8GA1UEBwwITXVlbmNoZW4xEDAOBgNVBAoMB1NpZW1lbnMx
        ETAPBgNVBAUTCFpaWlpaWkExMR0wGwYDVQQLDBRTaWVtZW5zIFRydXN0IENlbnRl
        cjEiMCAGA1UEAwwZU2llbWVucyBSb290IENBIFYzLjAgMjAxNjAeFw0xNjA3MjAx
        MzA5MDhaFw0yMjA3MjAxMzA5MDhaMIGfMQswCQYDVQQGEwJERTEPMA0GA1UECAwG
        QmF5ZXJuMREwDwYDVQQHDAhNdWVuY2hlbjEQMA4GA1UECgwHU2llbWVuczERMA8G
        A1UEBRMIWlpaWlpaQTIxHTAbBgNVBAsMFFNpZW1lbnMgVHJ1c3QgQ2VudGVyMSgw
        JgYDVQQDDB9TaWVtZW5zIElzc3VpbmcgQ0EgRUUgQXV0aCAyMDE2MIICIjANBgkq
        hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAy1aUq88DjZYPge0vZnAr3KJHmMi0o5mp
        hy54Xr592Vtf8u/B3TCyD+iGCYANPYUq4sG18qXcVxGadz7zeEm6RI7jKKl3URAv
        zFGiYForZE0JKxwo956T/diLLpH1vHEQDbp8AjNK7aGoltZnm/Jn6IVQy9iBY0SE
        lRIBhUlppS4/J2PHtKEvQVYJfkAwTtHuGpvPaesoJ8bHA0KhEZ4+/kIYQebaNDf0
        ltTmXd4Z8zeUhE25d9MzoFnQUg+F01ewMfc0OsEFheKWP6dmo0MSLWARXxjI3K2R
        THtJU5hxjb/+SA2wlfpqwNIAkTECDBfqYxHReAT8PeezvzEkNZ9RrXl9qj0Cm2iZ
        AjY1SL+asuxrGvFwEW/ZKJ2ARY/ot1cHh/I79srzh/jFieShVHbT6s6fyKXmkUjB
        OEnybUKUqcvNuOXnwEiJ/9jKT5UVBWTDxbEQucAarVNFBEf557o9ievbT+VAZKZ8
        F4tJge6jl2y19eppflresr7Xui9wekK2LYcLOF3X/MOCFq/9VyQDyE7X9KNGtEx7
        4V6J2QpbbRJryvavh3b0eQEtqDc65eiEaP8awqOErN8EEYh7Gdx4Um3QFcm1TBhk
        ZTdQdLlWv4LvIBnXiBEWRczQYEIm5wv5ZkyPwdL39Xwc72esPPBu8FtQFVcQlRdG
        I2t5Ywefq48CAwEAAaOCArIwggKuMIIBBQYIKwYBBQUHAQEEgfgwgfUwQQYIKwYB
        BQUHMAKGNWxkYXA6Ly9hbC5zaWVtZW5zLm5ldC9DTj1aWlpaWlpBMSxMPVBLST9j
        QUNlcnRpZmljYXRlMDIGCCsGAQUFBzAChiZodHRwOi8vYWguc2llbWVucy5jb20v
        cGtpP1paWlpaWkExLmNydDBKBggrBgEFBQcwAoY+bGRhcDovL2FsLnNpZW1lbnMu
        Y29tL3VpZD1aWlpaWlpBMSxvPVRydXN0Y2VudGVyP2NBQ2VydGlmaWNhdGUwMAYI
        KwYBBQUHMAGGJGh0dHA6Ly9vY3NwLnBraS1zZXJ2aWNlcy5zaWVtZW5zLmNvbTAf
        BgNVHSMEGDAWgBRwbaBQ7KnQLGedGRX+/QRzNcPi1DASBgNVHRMBAf8ECDAGAQH/
        AgEAMEAGA1UdIAQ5MDcwNQYIKwYBBAGhaQcwKTAnBggrBgEFBQcCARYbaHR0cDov
        L3d3dy5zaWVtZW5zLmNvbS9wa2kvMIHHBgNVHR8Egb8wgbwwgbmggbaggbOGP2xk
        YXA6Ly9jbC5zaWVtZW5zLm5ldC9DTj1aWlpaWlpBMSxMPVBLST9hdXRob3JpdHlS
        ZXZvY2F0aW9uTGlzdIYmaHR0cDovL2NoLnNpZW1lbnMuY29tL3BraT9aWlpaWlpB
        MS5jcmyGSGxkYXA6Ly9jbC5zaWVtZW5zLmNvbS91aWQ9WlpaWlpaQTEsbz1UcnVz
        dGNlbnRlcj9hdXRob3JpdHlSZXZvY2F0aW9uTGlzdDAzBgNVHSUELDAqBggrBgEF
        BQcDAgYIKwYBBQUHAwQGCisGAQQBgjcUAgIGCCsGAQUFBwMJMA4GA1UdDwEB/wQE
        AwIBBjAdBgNVHQ4EFgQUvb0qQyI9SEpXfpgxF6lwne6fqJkwDQYJKoZIhvcNAQEL
        BQADggIBAEQB0qDUmU8rX9KVJA/0zxJUmIeE9zeldih8TKrf4UNzS1+2Cqn4agO7
        MxRG1d52/pL4uKenffwwYy2dP912PwLjCDOL7jvojjQKx/qpVUXF7XWsg8hAQec3
        7Ras/jGPcPQ3OehbkcKcmXI4MrF0Haqo3q1n29gjlJ0fGn2fF1/CBnybPuODAjWG
        o9mZodXfz0woGSxkftC6nTmAV2GCvIU+j5hNKpzEzo8c1KwLVeXtB4PAqioRW1BX
        Ngjc7HQbvX/C39RnpOM3RdITw2KKXFxeKBMXdiDuFz/2CzO8HxKH9EVWEcSRbTnd
        E5iEB4CZzcvfzl9X5AwrKkiIziOiEoiv21ooWeFWfR9V2dgYIE7G1TFwsQ4p0/w5
        xBHSzqP8TCJp1MQTw42/t8uUXoFEGqk5FKQWoIaFf7N//FLAn8r+7vxNhF5s+tMl
        VsdKnXn3q8THB3JSnbb/AWGL9rjPK3vh2d3c0I5cWuKXexPLp74ynl2XUbiOXKE7
        XPUZ9qgK0G9JrrFMm4x1aID9Y9jqYeEz6krYjdFHo5BOVGso6SqWVJE48TxJ5KVv
        FUb4OxhOAw118Tco0XA7H1G3c2/AKJvIku3cRuj8eLe/cpKqUqQl8uikIZs7POaO
        +9eJsOnNPmUiwumJgwAo3Ka4ALteKZLbGmKvuo/2ueKCQ29F5rnOMYICOzCCAjcC
        AQEwgagwgZ8xCzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCYXllcm4xETAPBgNVBAcM
        CE11ZW5jaGVuMRAwDgYDVQQKDAdTaWVtZW5zMREwDwYDVQQFEwhaWlpaWlpBMjEd
        MBsGA1UECwwUU2llbWVucyBUcnVzdCBDZW50ZXIxKDAmBgNVBAMMH1NpZW1lbnMg
        SXNzdWluZyBDQSBFRSBBdXRoIDIwMTYCBGvn1/4wCwYJYIZIAWUDBAIBoGkwHAYJ
        KoZIhvcNAQkFMQ8XDTE5MDYyMDEwNDIwNlowLwYJKoZIhvcNAQkEMSIEIHPHp00z
        IZ93dAl/uwOnixzuAtf1fUTyxFFaq/5yzc+0MBgGCSqGSIb3DQEJAzELBgkqhkiG
        9w0BBwEwCwYJKoZIhvcNAQEBBIIBAD8Or5F/A/vpeNPv1YOrGzTrMU5pbn6o8t2+
        Hqn+hAdjbD26HqjYQN/nyXNBpgXiV4P5vEVNVpmViAAXGsWKM3BJx7GdH/uUwDnj
        upvoViXYtzQ92UC2Xzqo7uOg2ryMbDIFNfLosvy4a7NfDLYoMsVYrgOKpDrfOLsS
        1VNUjlyftm7vKigkJLrPIEmXrZSVEqsdKvFhcSxS55lm0lVd/fTCAi7TXR2FZWbc
        TrsTrZx2YdIJDwN04szzBjnQ7yJ4jBLYz1GMBe22xDD10UA4XdBYK07rkcabrv/t
        kUMI7uN/KeiKPeSvWCn3AUqH6TIFa9WU+tI4U2A2BsUMn6Bq9TY=
        -----END SIGNED MESSAGE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree 84c167013d2ee86e8a88ac6011df0b178d261a23
        parent e63f41fe459e62e1228fcef60d7189127aeba95a
        author Roger Meier <r.meier@siemens.com> 1561027326 +0200
        committer Roger Meier <r.meier@siemens.com> 1561027326 +0200

        feat: add a smime signed commit
      SIGNEDDATA
    end

    def certificate_crl
      'http://ch.siemens.com/pki?ZZZZZZA2.crl'
    end

    def certificate_serial
      1810356222
    end

    def certificate_subject_key_identifier
      'EC:00:B5:28:02:5C:D3:A5:A1:AB:C2:A1:34:81:84:AA:BF:9B:CF:F8'
    end

    def issuer_subject_key_identifier
      'BD:BD:2A:43:22:3D:48:4A:57:7E:98:31:17:A9:70:9D:EE:9F:A8:99'
    end

    def certificate_email
      'r.meier@siemens.com'
    end

    def certificate_issuer
      'CN=Siemens Issuing CA EE Auth 2016,OU=Siemens Trust Center,serialNumber=ZZZZZZA2,O=Siemens,L=Muenchen,ST=Bayern,C=DE'
    end

    def certificate_subject
      'CN=Meier Roger,O=Siemens,SN=Meier,GN=Roger,serialNumber=Z000NWDH'
    end

    def names
      ['Roger Meier']
    end

    def emails
      ['r.meier@siemens.com']
    end
  end
end

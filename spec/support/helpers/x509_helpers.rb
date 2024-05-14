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
        MIIGVTCCBD2gAwIBAgIEdikH4zANBgkqhkiG9w0BAQsFADCBmTELMAkGA1UEBhMC
        REUxDzANBgNVBAgMBkJheWVybjERMA8GA1UEBwwITXVlbmNoZW4xEDAOBgNVBAoM
        B1NpZW1lbnMxETAPBgNVBAUTCFpaWlpaWkExMR0wGwYDVQQLDBRTaWVtZW5zIFRy
        dXN0IENlbnRlcjEiMCAGA1UEAwwZU2llbWVucyBSb290IENBIFYzLjAgMjAxNjAe
        Fw0xNjA2MDYxMzMwNDhaFw0yODA2MDYxMzMwNDhaMIGZMQswCQYDVQQGEwJERTEP
        MA0GA1UECAwGQmF5ZXJuMREwDwYDVQQHDAhNdWVuY2hlbjEQMA4GA1UECgwHU2ll
        bWVuczERMA8GA1UEBRMIWlpaWlpaQTExHTAbBgNVBAsMFFNpZW1lbnMgVHJ1c3Qg
        Q2VudGVyMSIwIAYDVQQDDBlTaWVtZW5zIFJvb3QgQ0EgVjMuMCAyMDE2MIICIjAN
        BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAp2k2PcfRBu1yeXUxG3UoEDDTFtgF
        zGVNIq4j4g6niE7hxZzoferzgC6bK3y+lOQFfNkctFzjq6N+JvH535KnN4vXvNoO
        /Rvrn38XtUC8ms2/1MlzvFDMh0Rt1HzemJYsSUXPvj5EMjGVzeQu1/GZhN6XlRrc
        SgMSeuwAGN4IX/0QIyxaArxlDZks6zSOA+s9t2PBp6vPZcqA9y4RZLc33nQmdwZg
        onEYK55xS1QFY2/zuZGQtB73e69IsrAxP+ZzrivlpbgKkEb1kt0qd7rLkp/HnM9J
        IDFc6uo8dAUCA/oR40Yfe2+8hyKoTrFbTvxC2SqxoBolAemZ2rnckuQ1RInbCQNp
        pBJJr/Hg78yvIp65gP6mZsyhL6ZLLXjL+ICIUTU86OedkJ7j9o4vdrwBn8AugENy
        8jAMu06k9CFbe7QoEynlRvm5VoYMSBsMqn7lAmuBcuMHdEdXu/qN/ULRLGkx1QRc
        gqf7+QszYla8QEaTtxQKWfdAU0Fyg0ROagrBtFjuDjsMeLK6LM17K3FFM3pghISj
        o4A8+y2fSbKKnMvU1z3Zey6vnGSwZKOxMJy5/aWuERbegQ07iH0jaA7S/gKZhOKO
        uDHD9qOBYfKou6wC+xdWyPGFPOq8BQRkWrSEeQW9FxhyYhhcCdcRh+hpZ4eHgRLM
        KkiFrljndwyB4eUCAwEAAaOBojCBnzAfBgNVHSMEGDAWgBRwbaBQ7KnQLGedGRX+
        /QRzNcPi1DAPBgNVHRMBAf8EBTADAQH/MDwGA1UdIAQ1MDMwMQYEVR0gADApMCcG
        CCsGAQUFBwIBFhtodHRwOi8vd3d3LnNpZW1lbnMuY29tL3BraS8wDgYDVR0PAQH/
        BAQDAgEGMB0GA1UdDgQWBBRwbaBQ7KnQLGedGRX+/QRzNcPi1DANBgkqhkiG9w0B
        AQsFAAOCAgEAHAxI694Yl16uKvWUdGDoglYLXmTxkVHOSci3TxzdEsAJ6WEf7kbj
        6zSQxGcAOz7nvto80rOZzlCluoO5K5fD7a4nEKl+tuBPrgtcEE8nkspPJF6DwjHQ
        Lmh219YxktZ1D7egLaRCGvxbPjkb3Wuh4vLqzZHr8twcauMxMyqRTN5F2+F43MY0
        AeBIb9QIMYsxxLBxsSeg4aajGwhdj5FmDFUFbGlyIjd0FfnXxvMuRtWpUWOu4Tya
        kA0AX/q6uM/L9SFIwmzTO7+2AHW/m/HrCmWb6R4VYWAgppp+jhUViW5l1uLB3i4m
        5IaJHZilU/DwQ5FnkuP2xqLvZ7AF3uXBlldOAbE1327uGIhYgp40Oi7PIHH+vgwg
        JOXQJ3SMwEzYmxCNsyLKAJb2Gs1IpwEpz7lpitl7i/DeUlPZSAo+1SLzc7P35muX
        ukCeh1vR7LJdCeYQpDpKeUYjKaNXr2/rZlMFmOGXLBKQvTNcI2I5WTIbVQ1sxhWN
        0FS+INH6jUypiwh0WH2R1Bo0HY3Lq4zJJ3Ct/12ocQ78+JfENXI8glOs3H07jyng
        afEj0ba23cn4HnV8s4T0jt8KZYlNkSNlSJ5kgTaZjmdLbTbt24OO4f3WNRrINwKC
        VzrN1ydSBGHNOsb/muR5axK/dHN2TEycRJPO6kSaVclLhMTxEmhRBUE=
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

    def signed_commit_time
      Time.at(1561027326)
    end

    def signed_tag_time
      Time.at(1574261780)
    end

    def signed_tag_signature
      <<~SIGNATURE
        -----BEGIN SIGNED MESSAGE-----
        MIISfwYJKoZIhvcNAQcCoIIScDCCEmwCAQExDTALBglghkgBZQMEAgEwCwYJKoZI
        hvcNAQcBoIIP8zCCB3QwggVcoAMCAQICBBXXLOIwDQYJKoZIhvcNAQELBQAwgbYx
        CzAJBgNVBAYTAkRFMQ8wDQYDVQQIDAZCYXllcm4xETAPBgNVBAcMCE11ZW5jaGVu
        MRAwDgYDVQQKDAdTaWVtZW5zMREwDwYDVQQFEwhaWlpaWlpBNjEdMBsGA1UECwwU
        U2llbWVucyBUcnVzdCBDZW50ZXIxPzA9BgNVBAMMNlNpZW1lbnMgSXNzdWluZyBD
        QSBNZWRpdW0gU3RyZW5ndGggQXV0aGVudGljYXRpb24gMjAxNjAeFw0xNzAyMDMw
        NjU4MzNaFw0yMDAyMDMwNjU4MzNaMFsxETAPBgNVBAUTCFowMDBOV0RIMQ4wDAYD
        VQQqDAVSb2dlcjEOMAwGA1UEBAwFTWVpZXIxEDAOBgNVBAoMB1NpZW1lbnMxFDAS
        BgNVBAMMC01laWVyIFJvZ2VyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
        AQEAuBNea/68ZCnHYQjpm/k3ZBG0wBpEKSwG6lk9CEQlSxsqVLQHAoAKBIlJm1in
        YVLcK/Sq1yhYJ/qWcY/M53DhK2rpPuhtrWJUdOUy8EBWO20F4bd4Fw9pO7jt8bme
        u33TSrK772vKjuppzB6SeG13Cs08H+BIeD106G27h7ufsO00pvsxoSDL+uc4slnr
        pBL+2TAL7nSFnB9QHWmRIK27SPqJE+lESdb0pse11x1wjvqKy2Q7EjL9fpqJdHzX
        NLKHXd2r024TOORTa05DFTNR+kQEKKV96XfpYdtSBomXNQ44cisiPBJjFtYvfnFE
        wgrHa8fogn/b0C+A+HAoICN12wIDAQABo4IC4jCCAt4wHQYDVR0OBBYEFCF+gkUp
        XQ6xGc0kRWXuDFxzA14zMEMGA1UdEQQ8MDqgIwYKKwYBBAGCNxQCA6AVDBNyLm1l
        aWVyQHNpZW1lbnMuY29tgRNyLm1laWVyQHNpZW1lbnMuY29tMA4GA1UdDwEB/wQE
        AwIHgDAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwQwgcoGA1UdHwSBwjCB
        vzCBvKCBuaCBtoYmaHR0cDovL2NoLnNpZW1lbnMuY29tL3BraT9aWlpaWlpBNi5j
        cmyGQWxkYXA6Ly9jbC5zaWVtZW5zLm5ldC9DTj1aWlpaWlpBNixMPVBLST9jZXJ0
        aWZpY2F0ZVJldm9jYXRpb25MaXN0hklsZGFwOi8vY2wuc2llbWVucy5jb20vQ049
        WlpaWlpaQTYsbz1UcnVzdGNlbnRlcj9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0
        MEUGA1UdIAQ+MDwwOgYNKwYBBAGhaQcCAgMBAzApMCcGCCsGAQUFBwIBFhtodHRw
        Oi8vd3d3LnNpZW1lbnMuY29tL3BraS8wDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAW
        gBT4FV1HDGx3e3LEAheRaKK292oJRDCCAQQGCCsGAQUFBwEBBIH3MIH0MDIGCCsG
        AQUFBzAChiZodHRwOi8vYWguc2llbWVucy5jb20vcGtpP1paWlpaWkE2LmNydDBB
        BggrBgEFBQcwAoY1bGRhcDovL2FsLnNpZW1lbnMubmV0L0NOPVpaWlpaWkE2LEw9
        UEtJP2NBQ2VydGlmaWNhdGUwSQYIKwYBBQUHMAKGPWxkYXA6Ly9hbC5zaWVtZW5z
        LmNvbS9DTj1aWlpaWlpBNixvPVRydXN0Y2VudGVyP2NBQ2VydGlmaWNhdGUwMAYI
        KwYBBQUHMAGGJGh0dHA6Ly9vY3NwLnBraS1zZXJ2aWNlcy5zaWVtZW5zLmNvbTAN
        BgkqhkiG9w0BAQsFAAOCAgEAXPVcX6vaEcszJqg5IemF9aFTlwTrX5ITNIpzcqG+
        kD5haOf2mZYLjl+MKtLC1XfmIsGCUZNb8bjP6QHQEI+2d6x/ZOqPq7Kd7PwVu6x6
        xZrkDjUyhUbUntT5+RBy++l3Wf6Cq6Kx+K8ambHBP/bu90/p2U8KfFAG3Kr2gI2q
        fZrnNMOxmJfZ3/sXxssgLkhbZ7hRa+MpLfQ6uFsSiat3vlawBBvTyHnoZ/7oRc8y
        qi6QzWcd76CPpMElYWibl+hJzKbBZUWvc71AzHR6i1QeZ6wubYz7vr+FF5Y7tnxB
        Vz6omPC9XAg0F+Dla6Zlz3Awj5imCzVXa+9SjtnsidmJdLcKzTAKyDewewoxYOOJ
        j3cJU7VSjJPl+2fVmDBaQwcNcUcu/TPAKApkegqO7tRF9IPhjhW8QkRnkqMetO3D
        OXmAFVIsEI0Hvb2cdb7B6jSpjGUuhaFm9TCKhQtCk2p8JCDTuaENLm1x34rrJKbT
        2vzyYN0CZtSkUdgD4yQxK9VWXGEzexRisWb4AnZjD2NAquLPpXmw8N0UwFD7MSpC
        dpaX7FktdvZmMXsnGiAdtLSbBgLVWOD1gmJFDjrhNbI8NOaOaNk4jrfGqNh5lhGU
        4DnBT2U6Cie1anLmFH/oZooAEXR2o3Nu+1mNDJChnJp0ovs08aa3zZvBdcloOvfU
        qdowggh3MIIGX6ADAgECAgQtyi/nMA0GCSqGSIb3DQEBCwUAMIGZMQswCQYDVQQG
        EwJERTEPMA0GA1UECAwGQmF5ZXJuMREwDwYDVQQHDAhNdWVuY2hlbjEQMA4GA1UE
        CgwHU2llbWVuczERMA8GA1UEBRMIWlpaWlpaQTExHTAbBgNVBAsMFFNpZW1lbnMg
        VHJ1c3QgQ2VudGVyMSIwIAYDVQQDDBlTaWVtZW5zIFJvb3QgQ0EgVjMuMCAyMDE2
        MB4XDTE2MDcyMDEzNDYxMFoXDTIyMDcyMDEzNDYxMFowgbYxCzAJBgNVBAYTAkRF
        MQ8wDQYDVQQIDAZCYXllcm4xETAPBgNVBAcMCE11ZW5jaGVuMRAwDgYDVQQKDAdT
        aWVtZW5zMREwDwYDVQQFEwhaWlpaWlpBNjEdMBsGA1UECwwUU2llbWVucyBUcnVz
        dCBDZW50ZXIxPzA9BgNVBAMMNlNpZW1lbnMgSXNzdWluZyBDQSBNZWRpdW0gU3Ry
        ZW5ndGggQXV0aGVudGljYXRpb24gMjAxNjCCAiIwDQYJKoZIhvcNAQEBBQADggIP
        ADCCAgoCggIBAL9UfK+JAZEqVMVvECdYF9IK4KSw34AqyNl3rYP5x03dtmKaNu+2
        0fQqNESA1NGzw3s6LmrKLh1cR991nB2cvKOXu7AvEGpSuxzIcOROd4NpvRx+Ej1p
        JIPeqf+ScmVK7lMSO8QL/QzjHOpGV3is9sG+ZIxOW9U1ESooy4Hal6ZNs4DNItsz
        piCKqm6G3et4r2WqCy2RRuSqvnmMza7Y8BZsLy0ZVo5teObQ37E/FxqSrbDI8nxn
        B7nVUve5ZjrqoIGSkEOtyo11003dVO1vmWB9A0WQGDqE/q3w178hGhKfxzRaqzyi
        SoADUYS2sD/CglGTUxVq6u0pGLLsCFjItcCWqW+T9fPYfJ2CEd5b3hvqdCn+pXjZ
        /gdX1XAcdUF5lRnGWifaYpT9n4s4adzX8q6oHSJxTppuAwLRKH6eXALbGQ1I9lGQ
        DSOipD/09xkEsPw6HOepmf2U3YxZK1VU2sHqugFJboeLcHMzp6E1n2ctlNG1GKE9
        FDHmdyFzDi0Nnxtf/GgVjnHF68hByEE1MYdJ4nJLuxoT9hyjYdRW9MpeNNxxZnmz
        W3zh7QxIqP0ZfIz6XVhzrI9uZiqwwojDiM5tEOUkQ7XyW6grNXe75yt6mTj89LlB
        H5fOW2RNmCy/jzBXDjgyskgK7kuCvUYTuRv8ITXbBY5axFA+CpxZqokpAgMBAAGj
        ggKmMIICojCCAQUGCCsGAQUFBwEBBIH4MIH1MEEGCCsGAQUFBzAChjVsZGFwOi8v
        YWwuc2llbWVucy5uZXQvQ049WlpaWlpaQTEsTD1QS0k/Y0FDZXJ0aWZpY2F0ZTAy
        BggrBgEFBQcwAoYmaHR0cDovL2FoLnNpZW1lbnMuY29tL3BraT9aWlpaWlpBMS5j
        cnQwSgYIKwYBBQUHMAKGPmxkYXA6Ly9hbC5zaWVtZW5zLmNvbS91aWQ9WlpaWlpa
        QTEsbz1UcnVzdGNlbnRlcj9jQUNlcnRpZmljYXRlMDAGCCsGAQUFBzABhiRodHRw
        Oi8vb2NzcC5wa2ktc2VydmljZXMuc2llbWVucy5jb20wHwYDVR0jBBgwFoAUcG2g
        UOyp0CxnnRkV/v0EczXD4tQwEgYDVR0TAQH/BAgwBgEB/wIBADBABgNVHSAEOTA3
        MDUGCCsGAQQBoWkHMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuc2llbWVucy5j
        b20vcGtpLzCBxwYDVR0fBIG/MIG8MIG5oIG2oIGzhj9sZGFwOi8vY2wuc2llbWVu
        cy5uZXQvQ049WlpaWlpaQTEsTD1QS0k/YXV0aG9yaXR5UmV2b2NhdGlvbkxpc3SG
        Jmh0dHA6Ly9jaC5zaWVtZW5zLmNvbS9wa2k/WlpaWlpaQTEuY3JshkhsZGFwOi8v
        Y2wuc2llbWVucy5jb20vdWlkPVpaWlpaWkExLG89VHJ1c3RjZW50ZXI/YXV0aG9y
        aXR5UmV2b2NhdGlvbkxpc3QwJwYDVR0lBCAwHgYIKwYBBQUHAwIGCCsGAQUFBwME
        BggrBgEFBQcDCTAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFPgVXUcMbHd7csQC
        F5Foorb3aglEMA0GCSqGSIb3DQEBCwUAA4ICAQBw+sqMp3SS7DVKcILEmXbdRAg3
        lLO1r457KY+YgCT9uX4VG5EdRKcGfWXK6VHGCi4Dos5eXFV34Mq/p8nu1sqMuoGP
        YjHn604eWDprhGy6GrTYdxzcE/GGHkpkuE3Ir/45UcmZlOU41SJ9SNjuIVrSHMOf
        ccSY42BCspR/Q1Z/ykmIqQecdT3/Kkx02GzzSN2+HlW6cEO4GBW5RMqsvd2n0h2d
        fe2zcqOgkLtx7u2JCR/U77zfyxG3qXtcymoz0wgSHcsKIl+GUjITLkHfS9Op8V7C
        Gr/dX437sIg5pVHmEAWadjkIzqdHux+EF94Z6kaHywohc1xG0KvPYPX7iSNjkvhz
        4NY53DHmxl4YEMLffZnaS/dqyhe1GTpcpyN8WiR4KuPfxrkVDOsuzWFtMSvNdlOV
        gdI0MXcLMP+EOeANZWX6lGgJ3vWyemo58nzgshKd24MY3w3i6masUkxJH2KvI7UH
        /1Db3SC8oOUjInvSRej6M3ZhYWgugm6gbpUgFoDw/o9Cg6Qm71hY0JtcaPC13rzm
        N8a2Br0+Fa5e2VhwLmAxyfe1JKzqPwuHT0S5u05SQghL5VdzqfA8FCL/j4XC9yI6
        csZTAQi73xFQYVjZt3+aoSz84lOlTmVo/jgvGMY/JzH9I4mETGgAJRNj34Z/0meh
        M+pKWCojNH/dgyJSwDGCAlIwggJOAgEBMIG/MIG2MQswCQYDVQQGEwJERTEPMA0G
        A1UECAwGQmF5ZXJuMREwDwYDVQQHDAhNdWVuY2hlbjEQMA4GA1UECgwHU2llbWVu
        czERMA8GA1UEBRMIWlpaWlpaQTYxHTAbBgNVBAsMFFNpZW1lbnMgVHJ1c3QgQ2Vu
        dGVyMT8wPQYDVQQDDDZTaWVtZW5zIElzc3VpbmcgQ0EgTWVkaXVtIFN0cmVuZ3Ro
        IEF1dGhlbnRpY2F0aW9uIDIwMTYCBBXXLOIwCwYJYIZIAWUDBAIBoGkwHAYJKoZI
        hvcNAQkFMQ8XDTE5MTEyMDE0NTYyMFowLwYJKoZIhvcNAQkEMSIEIJDnZUpcVLzC
        OdtpkH8gtxwLPIDE0NmAmFC9uM8q2z+OMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0B
        BwEwCwYJKoZIhvcNAQEBBIIBAH/Pqv2xp3a0jSPkwU1K3eGA/1lfoNJMUny4d/PS
        LVWlkgrmedXdLmuBzAGEaaZOJS0lEpNd01pR/reHs7xxZ+RZ0olTs2ufM0CijQSx
        OL9HDl2O3OoD77NWx4tl3Wy1yJCeV3XH/cEI7AkKHCmKY9QMoMYWh16ORBtr+YcS
        YK+gONOjpjgcgTJgZ3HSFgQ50xiD4WT1kFBHsuYsLqaOSbTfTN6Ayyg4edjrPQqa
        VcVf1OQcIrfWA3yMQrnEZfOYfN/D4EPjTfxBV+VCi/F2bdZmMbJ7jNk1FbewSwWO
        SDH1i0K32NyFbnh0BSos7njq7ELqKlYBsoB/sZfaH2vKy5U=
        -----END SIGNED MESSAGE-----
      SIGNATURE
    end

    def signed_tag_base_data
      <<~SIGNEDDATA
      object 189a6c924013fc3fe40d6f1ec1dc20214183bc97
      type commit
      tag v1.1.1
      tagger Roger Meier <r.meier@siemens.com> 1574261780 +0100

      x509 signed tag
      SIGNEDDATA
    end

    def unsigned_tag_base_data
      <<~SIGNEDDATA
      object 6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9
      type commit
      tag v1.0.0
      tagger Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com> 1393491299 +0200

      Release
      SIGNEDDATA
    end

    def certificate_crl
      'http://ch.siemens.com/pki?ZZZZZZA2.crl'
    end

    def tag_certificate_crl
      'http://ch.siemens.com/pki?ZZZZZZA6.crl'
    end

    def certificate_serial
      1810356222
    end

    def tag_certificate_serial
      3664232660
    end

    def certificate_subject_key_identifier
      'EC:00:B5:28:02:5C:D3:A5:A1:AB:C2:A1:34:81:84:AA:BF:9B:CF:F8'
    end

    def tag_certificate_subject_key_identifier
      '21:7E:82:45:29:5D:0E:B1:19:CD:24:45:65:EE:0C:5C:73:03:5E:33'
    end

    def issuer_subject_key_identifier
      'BD:BD:2A:43:22:3D:48:4A:57:7E:98:31:17:A9:70:9D:EE:9F:A8:99'
    end

    def tag_issuer_subject_key_identifier
      'F8:15:5D:47:0C:6C:77:7B:72:C4:02:17:91:68:A2:B6:F7:6A:09:44'
    end

    def certificate_email
      'r.meier@siemens.com'
    end

    def tag_email
      'dmitriy.zaporozhets@gmail.com'
    end

    def certificate_issuer
      'CN=Siemens Issuing CA EE Auth 2016,OU=Siemens Trust Center,serialNumber=ZZZZZZA2,O=Siemens,L=Muenchen,ST=Bayern,C=DE'
    end

    def tag_certificate_issuer
      'CN=Siemens Issuing CA Medium Strength Authentication 2016,OU=Siemens Trust Center,serialNumber=ZZZZZZA6,O=Siemens,L=Muenchen,ST=Bayern,C=DE'
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

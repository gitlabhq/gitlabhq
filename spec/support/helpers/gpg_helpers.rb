module GpgHelpers
  SIGNED_COMMIT_SHA = '8a852d50dda17cc8fd1408d2fd0c5b0f24c76ca4'.freeze

  module User1
    extend self

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----
        Version: GnuPG v1

        iJwEAAECAAYFAliu264ACgkQzPvhnwCsix1VXgP9F6zwAMb3OXKZzqGxJ4MQIBoL
        OdiUSJpL/4sIA9uhFeIv3GIA+uhsG1BHHsG627+sDy7b8W9VWEd7tbcoz4Mvhf3P
        8g0AIt9/KJuStQZDrXwP1uP6Rrl759nDcNpoOKdSQ5EZ1zlRzeDROlZeDp7Ckfvw
        GLmN/74Gl3pk0wfgHFY=
        =wSgS
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree ed60cfd202644fda1abaf684e7d965052db18c13
        parent caf6a0334a855e12f30205fff3d7333df1f65127
        author Nannie Bernhard <nannie.bernhard@example.com> 1487854510 +0100
        committer Nannie Bernhard <nannie.bernhard@example.com> 1487854510 +0100

        signed commit, verified key/email
      SIGNEDDATA
    end

    def secret_key
      <<~KEY.strip
        -----BEGIN PGP PRIVATE KEY BLOCK-----
        Version: GnuPG v1

        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
        =b6UD
        -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mI0EWK7VJwEEANSFayuVYenl7sBKUjmIxwDRc3jd+K+FWUZgknLgiLcevaLh/mxV
        98dLxDKGDHHNKc/B7Y4qdlZYv1wfNQVuIbd8dqUQFOOkH7ukbgcGBTxH+2IM67y+
        QBH618luS5Gz1d4bd0YoFf/xZGEh9G5xicz7TiXYzLKjnMjHu2EmbFePABEBAAG0
        LU5hbm5pZSBCZXJuaGFyZCA8bmFubmllLmJlcm5oYXJkQGV4YW1wbGUuY29tPoi4
        BBMBAgAiBQJYrtUnAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRDM++Gf
        AKyLHaeSA/99oUWpb02PlfkALcx5RncboMHkgczYEU9wOFIgvXIReswThCMOvPZa
        piui+ItyJfV3ijJfO8IvbbFcvU7jjGA073Bb7tbzAEOQLA16mWgBLQlGaRWbHDW4
        uwFxvkJKA0GzEsadEXeniESaZPc4rOXKPO3+/MSQWS2bmvvGsBTEuriNBFiu1ScB
        BADIXkITf+kKCkD+n8tMsdTLInefu8KrJ8p7YRYCCabEXnWRsDb5zxUAG2VXCVUh
        Yl6QXQybkNiBaduS+uxilz7gtYZUMFJvQ09+fV7D2N9B7u/1bGdIYz+cDFJnEJit
        LY4w/nju2Sno5CL5Ead8sZuslKetSXPYHR/kbW462EOw5wARAQABiJ8EGAECAAkF
        Aliu1ScCGwwACgkQzPvhnwCsix2WRQQAtOXpBS60myrBUXhlcqabDQgSTw+Spbgb
        61hEMckyzpk7SfMNLz0EbYMvj9SU6znBG8RGeUljPTVMxPGr9yIpoFMSPKAUi/0K
        AgRmH3tVpxlMipwXjST1Jukk2eHckt/3jGw3E1ElMSFtULe6u5p4gu578hHukEwT
        IKzj0ZyC7DI=
        =Ug0r
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def public_key_with_extra_signing_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        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
        DMVGWrg4m1NF8N6yMPMP
        =RB1y
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def primary_keyid
      fingerprint[-16..-1]
    end

    def fingerprint
      '5F7EA3981A5845B141ABD522CCFBE19F00AC8B1D'
    end

    def names
      ['Nannie Bernhard']
    end

    def emails
      ['nannie.bernhard@example.com']
    end
  end

  module User2
    extend self

    def private_key
      <<~KEY.strip
        -----BEGIN PGP PRIVATE KEY BLOCK-----
        Version: GnuPG v1

        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
        =yEqv
        -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mI0EWK6qKgEEAODjqOSIBNYzL23WenEVYnvvGJs9d1SjfosBmBnq4a6eBLNwUvjn
        Rt0TIwwablEmnoMJiRmXBAOUz/9gSrB/QKar8CJsLmb1sevuF/mwzGXjSywnh+N3
        NPqh2KE7S/EPYBFKu2LCQRLMXGMnnWaM590+8AZ/S5zHOB5F9SUKszeTABEBAAG0
        L0JldHRlIENhcnR3cmlnaHQgPGJldHRlLmNhcnR3cmlnaHRAZXhhbXBsZS5jb20+
        iLgEEwECACIFAliuqioCGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEL+d
        kl+RHv1lQhsD/0LDi008hCeoZdGMuwy2N5FMUusYg/X1tRQ6E0JcYYjvvE5oIZoX
        bVN0yLLD99P0rt6TSlt05CC7RPVPCNpKxKbF+TZMjMJiOi13XmY5Yti77ZMdBZtD
        7HeBzjkWCVuR6k8eIwy83niHGI6p6G87Q6XxvDjQ7wdBCNBpwkzmTYIBtC9CZXR0
        ZSBDYXJ0d3JpZ2h0IDxiZXR0ZS5jYXJ0d3JpZ2h0QGV4YW1wbGUubmV0Poi4BBMB
        AgAiBQJYrwLFAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRC/nZJfkR79
        ZVzsBADYe3Hv71I7+lTJDvKOTmV7M4ShOfjEpmDvL/5JB3FzXHAucCOlReCv/6+N
        afAspPTc1uys47dvtePwQalroAsd8Y1grn/PCh+Tx27kpn1WG8yZjUsuq3z5rrGR
        uXj6g8aeZdqkMTHUVF9Gd+g/5KDODdJbOjwH+l63b/bOiATDFbiNBFiuqioBBADe
        5nUdVOcbZlnxOjl0KBAT+A5bmyBLUT0BmLPsmA4PuXDSth7WvibPC8wcCdCYVk0I
        RMYneZUiWq/o5c4rthfLR4jg8kruvomQ4E4d4hyI6R0MLxXYZ3XMu67VuScFgbLU
        Rw1eRZ16ANd3Nc1VuFW7ms0vCG0idB8iSZBoULaK8QARAQABiJ8EGAECAAkFAliu
        qioCGwwACgkQv52SX5Ee/WVCCAQA1bBDCuVPYEUtZXwXH7CWDfX6ZyOROrQtpa7e
        i54CW6hKX3fYHpOiu4yHromjGlINTjjHclsJpn/qmiJizkB9/xl7IRWV+RVpDshZ
        3mymOldpLiKgI5+Rl6mZtO4TtM9BYziIEC24h+IkaLBylZYz4ogfbzXKF8JxtHPM
        UuwJVDE=
        =0vYo
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def primary_keyid
      fingerprint[-16..-1]
    end

    def fingerprint
      '6D494CA6FC90C0CAE0910E42BF9D925F911EFD65'
    end

    def names
      ['Bette Cartwright', 'Bette Cartwright']
    end

    def emails
      ['bette.cartwright@example.com', 'bette.cartwright@example.net']
    end
  end

  # GPG Key with extra signing key
  module User3
    extend self

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----

        iQEzBAABCAAdFiEEBSLdKbmPFnzYQhdS44/8r3Wr2SoFAlnNlT8ACgkQ44/8r3Wr
        2SqP1wf9FC4J2S8LIHs/fpxgkYzsyCp5lCbS7JuoD4pqmI2KWyBx+vi9/3mZPCsm
        Fj9f0vFEtNOb39GNGZbaA8DdGw30/WAS6kI6yco0WSK53KHrLw9Kqd+3e/NAVSsl
        991Gq4n8X1U5izSH+gZOMtEEUBGqIlZKgRrEh7lhNcz0G7JTF2VCE4NNtZdq7GDA
        N6jOQxDGUwi9wQBYORQzIBc3NihfhGloII1hXf0XzrgUY3zNYHTT7QipCxKAmH54
        skwW+wi8RpBedar4saf7fs5xZbP/0yyVz98MJMdHBL68++Xt1AIHoqrb7eWszqnd
        PCo/fnz1iHKCig602KLj0/zhADcNkg==
        =LsTi
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree 86ec18bfe87ad42a782fdabd8310f9b7ac750f51
        parent 2d1096e3a0ecf1d2baf6dee036cc80775d4940ba
        author John Doe <john.doe@example.com> 1506645311 -0500
        committer John Doe <john.doe@example.com> 1506645311 -0500

        Commit signed with subkey by John Doe
      SIGNEDDATA
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        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
        /jQYeOgFDKq20x86WulkvsUtBoaZJg==
        =Q5Z7
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def secret_key
      <<~SECRET
        -----BEGIN PGP PRIVATE KEY BLOCK-----

        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
        Jg==
        =TKlF
        -----END PGP PRIVATE KEY BLOCK-----
      SECRET
    end

    def fingerprint
      'EA3F8B88972A8FD474872F2F115B3AF1AAD3EDBA'
    end

    def subkey_fingerprints
      %w(159AD5DDF199591D67D2B87AA3CEC5C0A7C270EC 0522DD29B98F167CD8421752E38FFCAF75ABD92A)
    end

    def names
      ['John Doe']
    end

    def emails
      ['john.doe@example.com']
    end
  end

  # GPG Key containing just the main key
  module User4
    extend self

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mQENBFnWcesBCAC6Y8FXl9ZJ9HPa6dIYcgQrvjIQcwoQCUEsaXNRpc+206RPCIXK
        aIYr0nTD8GeovMuUONXTj+DdueQU2GAAqHHOqvDDVXqRrW3xfWnSwix7sTuhG1Ew
        PLHYmjLENqaTsdyliEo3N8VWy2k0QRbC3R6xvop4Ooa87D5vcATIl0gYFtSiHIL+
        TervYvTG9Eq1qSLZHbe2x4IzeqX2luikPKokL7j8FTZaCmC5MezIUur1ulfyYY/j
        SkST/1aUFc5QXJJSZA0MYJWZX6x7Y3l7yl0dkHqmK8OTuo8RPWd3ybEiuvRsOL8K
        GAv/PmVJRGDAf7GGbwXXsE9MiZ5GzVPxHnexABEBAAG0G0pvaG4gRG9lIDxqb2hu
        QGV4YW1wbGUuY29tPokBTgQTAQgAOBYhBAh0izYM0lwuzJnVlAcBbPnhOj+bBQJZ
        1nHrAhsDBQsJCAcCBhUICQoLAgQWAgMBAh4BAheAAAoJEAcBbPnhOj+bkywH/i4w
        OwpDxoTjUQlPlqGAGuzvWaPzSJndawgmMTr68oRsD+wlQmQQTR5eqxCpUIyV4aYb
        D697RYzoqbT4mlU49ymzfKSAxFe88r1XQWdm81DcofHVPmw2GBrIqaX3Du4Z7xkI
        Q9/S43orwknh5FoVwU8Nau7qBuv9vbw2apSkuA1oBj3spQ8hqwLavACyQ+fQloAT
        hSDNqPiCZj6L0dwM1HYiqVoN3Q7qjgzzeBzlXzljJoWblhxllvMK20bVoa7H+uR2
        lczFHfsX8VTIMjyTGP7R3oHN91DEahlQybVVNLmNSDKZM2P/0d28BRUmWxQJ4Ws3
        J4hOWDKnLMed3VOIWzM=
        =xVuW
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def secret_key
      <<~KEY.strip
        -----BEGIN PGP PRIVATE KEY BLOCK-----

        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
        =/37z
        -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def primary_keyid
      fingerprint[-16..-1]
    end

    def fingerprint
      '08748B360CD25C2ECC99D59407016CF9E13A3F9B'
    end
  end
end

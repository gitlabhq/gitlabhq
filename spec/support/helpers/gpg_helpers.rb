# frozen_string_literal: true

module GpgHelpers
  SIGNED_COMMIT_SHA       = '8a852d50dda17cc8fd1408d2fd0c5b0f24c76ca4'
  SIGNED_AND_AUTHORED_SHA = '3c1d9a0266cb0c62d926f4a6c649beed561846f5'
  DIFFERING_EMAIL_SHA     = 'a17a9f66543673edf0a3d1c6b93bdda3fe600f32'
  MULTIPLE_SIGNATURES_SHA = 'c7794c14268d67ad8a2d5f066d706539afc75a96'

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
      fingerprint[-16..]
    end

    def fingerprint
      '5F7EA3981A5845B141ABD522CCFBE19F00AC8B1D'
    end

    # passphrase for secret key 2 is:
    # qHGKKXBZ72VamRMUH6d7LsLWsHnJJx3p
    def secret_key2
      <<~KEY.strip
      -----BEGIN PGP PRIVATE KEY BLOCK-----

      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
      =VtBY
      -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def public_key2
      <<~KEY.strip
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      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
      7ysn+Hu60VIDw8enikBOwZE1oTbrKiTywMbufg==
      =cp3L
      -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def primary_keyid2
      fingerprint2[-16..]
    end

    def fingerprint2
      'EC164842311CCF9F005DA1A34FD830CEB3E86C97'
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
      fingerprint[-16..]
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

        iQIzBAABCAAdFiEEOtBpdPeN0WA9XkYX0JVdIvLDJOIFAl2QZqAACgkQ0JVdIvLD
        JOKeGw//b1hJ/ZVNc/iBoDd5rOgjTm50tU+7n+y1wbodVQoDWxeObZpS6Rfo2b63
        U8WrGrePdP9QLTqMKRpJlZ0SnVFRTUC2eTO1zL527fDOXnyaUxPiBlBDGi3EaSGL
        qzsDB5oH8gJY9TyZ3uczYMyAKzMGuRCkLkEgKV6JCTK8MWpKWOIJ6Y9Za9xkn83g
        w+/3aQDBk2kVL3LAD8XxGNkji8agvoIv0l8gefXAT1tyhu0PIHbWu2FUX0+gQnVY
        6TlwiA+xpOY+nwg/yPL/CKFkHg84lTuZ3jrvndCjAv5erHrW/3H6b15e63Iu/vyn
        1NZpZoY+/DjIKtxyB7JepC+VTzRui2NtYm6d1YWqrHo+kDxh6q1FDXuAxm/SxZh3
        N8ybHvjq0S1pv6y21VCMV0aBAsgk9OhspO2n3VdcX2eUOvwNaZCVn6jOVcriwrF7
        SjDeXenF9sDclRx3OHx9qs3H9/ayRBROWjnJHeqsiJeJi7NlgndFmzXcqJMURGxM
        6Tgrd1KczRKOvS3rkl//3EP7HCsrg/0VNiSdeRjEvkqjyb7HNhOFAz41hPsad4Gj
        SXC9/HWFQjGxzwk2GSoYh5np+rDLgTfhISrXeQD4c8pb7NqoB7mlnwp7xza+cwGd
        Ggo/XNakLZJDpRSABKqCJ5QUzc8Q5IhRQFOKeV2w/LISGTIJvYk=
        =GGuq
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree 2bdf04adb23d2b40b6085efb230856e5e2a775b7
        parent 3e08e7c44e3005032d3de125697883797f9bd035
        author John Doe <john.doe@example.com> 1569744544 +1300
        committer John Doe <john.doe@example.com> 1569744544 +1300

        Commit signed with subkey by John Doe
      SIGNEDDATA
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        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
        embi+Bu7rmDr/adQN4wqXHHNIYEd2/h4D2Y=
        =jT2d
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    # passphrase for secret key is:
    # 4a45718624c9939a043471d83d1eda7c
    def secret_key
      <<~SECRET
        -----BEGIN PGP PRIVATE KEY BLOCK-----

        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
        2/h4D2Y=
        =NmAP
        -----END PGP PRIVATE KEY BLOCK-----
      SECRET
    end

    def fingerprint
      'C2974438C6A8FACC3371291D28595021633C8421'
    end

    def subkey_fingerprints
      %w[65A33805A5DDA7454190EE536F0E46B850B18E99 3AD06974F78DD1603D5E4617D0955D22F2C324E2]
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
      fingerprint[-16..]
    end

    def fingerprint
      '08748B360CD25C2ECC99D59407016CF9E13A3F9B'
    end
  end

  # A key carrying one live UID, one revoked UID and a signing subkey. The
  # revoked UID is still part of the key, since revoking a UID adds a
  # revocation signature rather than removing the UID. Both signatures were
  # made under the live UID: one with the primary key, one with the subkey.
  module UserWithRevokedUid
    extend self

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----

        iQEzBAABCgAdFiEE2C1NbV0gUVARQOIy1UJijUNKz+MFAmqnurEACgkQ1UJijUNK
        z+PjUQgAt9e4fz2J4USLD6eL9tmPqpFdak3eQ6uBKgtT/hQZ13Nkbip6JgtKiDpS
        CK/IKKQTnvR271CGK+xA0ClKHupI0bPxQhdgNZTT3fkPRB9xDnuVLteJ1bFMXuQj
        8T/zGkImZLSsX1+o2DRztmL7il4AL+epWkbtMfTotls9hNFnFZkxWwOYcNhYIQ5Q
        /EFFpnPnHxEf266cYRA8AFqDOdpysFIiyZmXg/erLu9X7D58wSPi8l2tTOmi3S9p
        LICbat2+aKbtX8nyKth3IZPtSmS5CXt3LkEG3FqFcCChSPf586EmHkX8fJWN3TdO
        Y+tTSM0dGOeqlx7uvoA6A4aleas1/Q==
        =t108
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
        parent 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
        author Sarah Mueller <sarah.mueller@example.com> 1789372255 +0200
        committer Sarah Mueller <sarah.mueller@example.com> 1789372255 +0200

        Commit signed by Sarah Mueller with her primary key
      SIGNEDDATA
    end

    def subkey_signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----

        iQEzBAABCgAdFiEE1S0LJ7glxRBwlV0F3v68vjWScA8FAmqnurEACgkQ3v68vjWS
        cA8LkAf/dpy3BQ9aC3TMf1mlEpywo3OFv09r7V8Q+eUtufZpXbS0YsK10jYRxwHh
        N2z+Tx/PIxAaFN8Ydxido5bYCyB90AJLYWHp5y9g/4QwxGpyqEHzWztf1/W9UTKp
        j7pNCY5+He4RjOQB1DB5EaQdFhwvwvRvCd75+scuNZ9tQmwGaJ5FQnZOK6DtGcsU
        W2mKZcw8xUlb/lF/JuMb6l3F3b3Izc9WJWVS9l0qHZKYOATNWlMysA8MLwsrF3/U
        oOzn+QiyiNlcg7Cg9lTzkTDYADwjWqD3tn4IcN72oPHmRYXvn3ZqOWMI7R+m6ZND
        hi62HcnkZIaLV9o0dhIWDi+zNDJJXg==
        =LS94
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def subkey_signed_commit_base_data
      <<~SIGNEDDATA
        tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
        parent 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
        author Sarah Mueller <sarah.mueller@example.com> 1789372256 +0200
        committer Sarah Mueller <sarah.mueller@example.com> 1789372256 +0200

        Commit signed by Sarah Mueller with her signing subkey
      SIGNEDDATA
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        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
        =Gqdc
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def secret_key
      <<~KEY.strip
        -----BEGIN PGP PRIVATE KEY BLOCK-----

        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
        =5Oal
        -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def primary_keyid
      fingerprint[-16..]
    end

    def fingerprint
      'D82D4D6D5D2051501140E232D542628D434ACFE3'
    end

    def subkey_fingerprints
      %w[D52D0B27B825C51070955D05DEFEBCBE3592700F]
    end

    def names
      ['Sarah Mueller']
    end

    def emails
      ['sarah.mueller@example.com']
    end

    def revoked_emails
      ['sarah.mueller@oldcompany.example.com']
    end
  end

  # A key whose only remaining UID is revoked. GnuPG refuses to revoke the last
  # valid UID of a key, so this one was built by revoking one UID and deleting
  # the other. GnuPG still signs with such a key, and the signature verifies.
  module UserWithOnlyRevokedUid
    extend self

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----

        iQEzBAABCgAdFiEERdlyqGGNKFRgqBfj17YqrefBT8kFAmqnutUACgkQ17YqrefB
        T8lShgf/eCZg98kZrsUrgbi7pTC0J6nkV2NAUwN/SYOvl4AALwxwn54X1zcgoy4Z
        ToFap3TPgYtJ1YhdUnap09at3fC9tpImxJsFoh8S5tRPPTA/OhrBFFOqKSg+9U2O
        T1fZcZWMbASioNnm5IXf5j/bf875l+VbqMF0enXT1hg++d449Yt/cMUGAF9Q107c
        cQe5sVviT2YraLxDt39gUhcyNN7faMmEgew4pCaRRWg4o5GAvRSvPXKhvbswndai
        VDo3wwF+vXPNWbbgOFM9Eprdyc3U5iZDmDnVGSAYG2w9RxJI2M/bW0RaeWLawQVN
        CTg6Ne61jebRrlB3IsKH6ykEB9K6Cg==
        =2Ufq
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
        parent 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
        author Tomas Novak <tomas.novak@former.example.com> 1789372314 +0200
        committer Tomas Novak <tomas.novak@former.example.com> 1789372314 +0200

        Commit signed by Tomas Novak under a uid he has since revoked
      SIGNEDDATA
    end

    def public_key
      <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mQENBGqnutUBCADQeo0YkEfLPtA24+YPhyZzg7cWZ4vQsvoCUnGwnARYopF0OxWe
        ONCkP4NJQX0FBwPjslUSbSDiVWapcOjyKlHWffZxzlViqz9lORPRL4ECLX62Bak5
        0UCBQPh7PlMZ1i33ABLn34gDPSXqW25biHeRAH6lzIGnYWkgjJyQU//5aKvy5ndK
        VilYX+LsLCcM8CLvVf87nSl3n+9oXqpQOAQ9Pmqbmk4EU/jU9iKJL6p8ft2Yda10
        ZTqi9ClgUtdvQy2kJS1YVErL0rHmCWDFMeHHuysuKoY78/UUxFdl9KPeZqO6ReE/
        AkVB64R50nOr7sAoRED0EQXZg5we+Q0wi1HpABEBAAG0LFRvbWFzIE5vdmFrIDx0
        b21hcy5ub3Zha0Bmb3JtZXIuZXhhbXBsZS5jb20+iQE2BDABCgAgFiEERdlyqGGN
        KFRgqBfj17YqrefBT8kFAmqnutYCHSAACgkQ17YqrefBT8mfdQf/TenAiOygIX+o
        MILj5k7gweT/Mee5D3Z3CgIVcTe0dX3w0IDwmXdgm0v2/nkMaj4ROXd9w3CE+ogn
        dWhnY0D9Z7k/NbtKK4/sSLAW9HSAZijMPnfFE9kHTSA51jQRHHzedg4SHx3jBSaC
        eK5/3D8ytKUkqANL0heeDUGzyGU/Ya8HATVyuznIRhjImzKBNLmrKSeaMraNq02+
        qWRIgDguaywe7Pi5pv7dy7chCEt4mkGxEmhWiyT3wDwcTXJv7zzb7SjwB4Hu5Nxs
        +mc62bMVbnwYJPa9nAmMYvM6soJVqArAnkoZjLc8DmbjZDFieoAAB3kE2iTiyXFa
        BJ1CEmVfV4kBTgQTAQoAOBYhBEXZcqhhjShUYKgX49e2Kq3nwU/JBQJqp7rVAhsD
        BQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJENe2Kq3nwU/Jnh4H/iyOH+xcIBQF
        xnCr5SM+vTAruwA3jX/nbakSZP0siDhtKttetAA9ldUnd1hqJcEX4bH/LV9WBZgY
        3TV8MDOsxy9a8zXyASmWLphY+JpKrDKJ7HJnd/vJhy33cTaXxGJj5cxRqFqEKbZn
        +9NLSOrn02JYzu5CFMpZnst0fHQqgzCa49x7qP8Kl7FyYyA2S2b0mDNb2zYNEwsq
        wxfDdKlq4tMrwWALBDy5o8qlU8uyqW7hRFPjd4msFybHXuA2boZA3QNc/bAUHAyQ
        d5/T4wGkSC2ZBMBlg2aC4FiCpX91TyMJxWxDrUuppbkW1L4gRCyM4R1SXuHzVYIL
        xTJTP+UN0Xk=
        =T3j4
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def secret_key
      <<~KEY.strip
        -----BEGIN PGP PRIVATE KEY BLOCK-----

        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
        =YnHn
        -----END PGP PRIVATE KEY BLOCK-----
      KEY
    end

    def primary_keyid
      fingerprint[-16..]
    end

    def fingerprint
      '45D972A8618D285460A817E3D7B62AADE7C14FC9'
    end

    def revoked_emails
      ['tomas.novak@former.example.com']
    end
  end
end

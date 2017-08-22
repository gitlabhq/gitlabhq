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
end

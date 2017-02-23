module GpgHelpers
  module User1
    extend self

    def signed_commit_signature
      <<~SIGNATURE
        -----BEGIN PGP SIGNATURE-----
        Version: GnuPG v1

        iQEcBAABAgAGBQJYpIi9AAoJEMcorxCXLpfAZZIH/R/nhcC4s0j6nqAsi9Kbc4DX
        TGZyfjed6puWzqnT90Vy+WyUC7FjWJpkuOKQz+NQD9JcBMRp/OC0GtkNz4djv1se
        Nup29qWd+Fg2XGEBakTxAo2e9cg38a2rGEIL6V8i+tYAhDt5OyLdzD/XsF0vt02E
        ZikSvV02c6ByrjPq37ZdOgnk1xJrS1NM0Sn4B7L3cAz6TYb1OvyG1Z4HnMWgTBHy
        e/uKLPRYhx7a4D4TEt4/JWN3sb0VnaToG623EdJ1APF/MK9Es+H7YfgBsyu18nss
        705F+PZ2vx/1b9z5dLc/jQNf+k9vQH4uhmOFwUJnuQ/qB4/3H/UyLH/HfomK7Zk=
        =fzCF
        -----END PGP SIGNATURE-----
      SIGNATURE
    end

    def signed_commit_base_data
      <<~SIGNEDDATA
        tree ed60cfd202644fda1abaf684e7d965052db18c13
        parent 4ded8b5ce09d2b665e5893945b29d8d626691086
        author Alexis Reigel <mail@koffeinfrei.org> 1487177917 +0100
        committer Alexis Reigel <mail@koffeinfrei.org> 1487177917 +0100

        signed commit, verified key/email
      SIGNEDDATA
    end

    def public_key
      <<~PUBLICKEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        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
        =1CGB
        -----END PGP PUBLIC KEY BLOCK-----
      PUBLICKEY
    end

    def key_id
      '972E97C0'
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
        7HeBzjkWCVuR6k8eIwy83niHGI6p6G87Q6XxvDjQ7wdBCNBpwkzmTYIBuI0EWK6q
        KgEEAN7mdR1U5xtmWfE6OXQoEBP4DlubIEtRPQGYs+yYDg+5cNK2Hta+Js8LzBwJ
        0JhWTQhExid5lSJar+jlziu2F8tHiODySu6+iZDgTh3iHIjpHQwvFdhndcy7rtW5
        JwWBstRHDV5FnXoA13c1zVW4VbuazS8IbSJ0HyJJkGhQtorxABEBAAGInwQYAQIA
        CQUCWK6qKgIbDAAKCRC/nZJfkR79ZUIIBADVsEMK5U9gRS1lfBcfsJYN9fpnI5E6
        tC2lrt6LngJbqEpfd9gek6K7jIeuiaMaUg1OOMdyWwmmf+qaImLOQH3/GXshFZX5
        FWkOyFnebKY6V2kuIqAjn5GXqZm07hO0z0FjOIgQLbiH4iRosHKVljPiiB9vNcoX
        wnG0c8xS7AlUMQ==
        =Erp5
        -----END PGP PUBLIC KEY BLOCK-----
      KEY
    end

    def key_id
      '911EFD65'
    end

    def signature
      '6D494CA6FC90C0CAE0910E42BF9D925F911EFD65'
    end
  end
end

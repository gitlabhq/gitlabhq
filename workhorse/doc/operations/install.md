# Installation

To install GitLab Workhorse you need [Go 1.15 or
newer](https://golang.org/dl) and [GNU
Make](https://www.gnu.org/software/make/).

To install into `/usr/local/bin` run `make install`.

```
make install
```

To install into `/foo/bin` set the PREFIX variable.

```
make install PREFIX=/foo
```

On some operating systems, such as FreeBSD, you may have to use
`gmake` instead of `make`.

*NOTE*: Some features depends on build tags, make sure to check
[Workhorse configuration](doc/operations/configuration.md) to enable them.

## Run time dependencies

### Exiftool

Workhorse uses [exiftool](https://www.sno.phy.queensu.ca/~phil/exiftool/) for
removing EXIF data (which may contain sensitive information) from uploaded
images. If you installed GitLab:

-   Using the Omnibus package, you're all set.
    *NOTE* that if you are using CentOS Minimal, you may need to install `perl`
    package: `yum install perl`
-   From source, make sure `exiftool` is installed:

    ```sh
    # Debian/Ubuntu
    sudo apt-get install libimage-exiftool-perl

    # RHEL/CentOS
    sudo yum install perl-Image-ExifTool
    ```

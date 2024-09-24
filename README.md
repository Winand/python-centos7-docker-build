# Build Python for CentOS 7 in Docker container
Run `docker-compose.yml` to build Python for CentOS 7.

Options are set in `.env`:
- `PYTHON_VERSION` - Python version to build (e. g. `3.12.0`)
- `OPENSSL_VERSION` - OpenSSL version to build (`1.1.1w` by default)
- `INSTALL_PATH` - Python and OpenSSL install path (e. g. `/home/user/.local`)

Note: `tkinter` module is not built.

# Links
- [#121992 Using custom OpenSSL version 3.x <...>](https://github.com/python/cpython/issues/121992)
- [#87632 --with-openssl-rpath](https://github.com/python/cpython/issues/87632)

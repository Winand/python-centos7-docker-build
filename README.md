# Build Python for CentOS 7 in Docker container
Run `docker-compose.yml` to build Python for CentOS 7.

Options are set in `docker-compose.yml`:
- `PYTHON_VERSION` - Python version to build (`3.12.0` by default)
- `OPENSSL_VERSION` - OpenSSL version to build (`1.1.1w` by default)
- `INSTALL_PATH` - Python and OpenSSL install path (e. g. `/home/user/.local`)

Note: `tkinter` module is not built.

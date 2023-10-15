fn main() {
    openssl::ssl::SslConnector::builder(openssl::ssl::SslMethod::tls()).unwrap();
}

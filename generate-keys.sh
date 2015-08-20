# Ensure correct folder
cd $(dirname $0)

# Generate private key
echo Generating private key
openssl genrsa -des3 -out server.key 2048

# Generate CSR
echo Generating CSR
openssl req -new -key server.key -out server.csr

# Remove passphrase
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key

# Generate self-signed cert
echo Signing certificate
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# Clean up
rm server.csr
rm server.key.org

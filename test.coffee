usableGPG = require './index'

gpg = new usableGPG(fullName: 'mzdunek', email: 'mzdunek@example.com', passphrase: 'abc')

gpg.createKey('RSA', 4096, 'ELG-E', 4096, 0)
.then () ->
    gpg.strengthenHash('SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed')
.then () ->
    gpg.addSubkey(4096)
.then () ->
    gpg.generateRevKey('mzdunek@example.com')
.then () ->
    gpg.exportPrivateKey('mzdunek@example.com')
.then () ->
    gpg.exportPublicKey('mzdunek@example.com')
.then () ->
    gpg.exportSubkeys('/dev/shm/subkeys')
.then () ->
    gpg.removeOriginalSubkey()
.then () ->
    gpg.importSubkeys('/dev/shm/subkeys')
.catch () ->
    console.log('error')
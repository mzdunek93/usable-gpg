# dependent on native gpg v1.*
gpg = require 'gpg'
{ Promise } = require 'bluebird'
fs = require 'fs'
        
class usableGPG 
  constructor: (@fullName, @email, @passphrase, @keyName) ->
    @defArgs = ["--no-default-keyring", "--secret-keyring", "keys/#{@keyName}.sec", "--keyring", "keys/#{@keyName}.pub", 
    "--no-batch", "--passphrase-fd", "0", "--command-fd", "0"]

  callGPG = (input, args) ->
    new Promise (resolve, reject) ->
      gpg.call input, args, (err, res) ->
        if err 
          reject(err)
        else
          resolve(res)
    
  createKey: (keyType, keyLength, subkeyType, subkeyLength, expireDate) -> 
    key = \
      "Key-Type: #{keyType}\nKey-Length: #{keyLength}\nSubkey-Type: #{subkeyType}\nSubkey-Length: #{subkeyLength}\nName-Real: #{@fullName}\nName-Comment: nope\nName-Email: #{@email}\nExpire-Date: #{expireDate}\nPassphrase: #{@passphrase}\n%secring keys/#{@keyName}.sec\n%pubring keys/#{@keyName}.pub\n%commit\n"
    callGPG(key, ['-v', '--batch', '--gen-key'])

  strengthenHash: (hashType) ->
    args = @defArgs.concat ["--edit-key", "#{@email}"]
    callGPG("#{@passphrase} setpref #{hashType}\ny\nsave", args)

  addSubkey: (length) ->
    args = @defArgs.concat ["--edit-key", "#{@email}", "addkey"]
    callGPG("#{@passphrase}\n4\n#{length}\n0\ny\ny\nsave\n", args)

  generateRevKey: (location) ->
    args = @defArgs.concat ["--output", "#{location}.gpg-revocation-certificate", "--gen-revoke", "#{@email}"]
    callGPG("#{@passphrase}\ny\n1\n\ny\n", args)

  exportPrivateKey: (location) ->
    args = @defArgs.concat ["--export-secret-keys", "--armor", "#{@email}"]
    callGPG("#{@passphrase}", args).then (res) ->
      fs.writeFileSync("#{location}.private.gpg-key", res.toString());

  exportPublicKey: (location) ->
    args = @defArgs.concat ["--export", "--armor", "#{@email}"]
    callGPG("#{@passphrase}", args).then (res) ->
      fs.writeFileSync("#{location}.public.gpg-key", res.toString());

  exportSubkeys: (location) ->
    args = @defArgs.concat ["--export-secret-subkeys", "#{@email}"]
    callGPG("#{@passphrase}", args).then (res) ->
      wstream = fs.createWriteStream(location)
      wstream.write(res)
      wstream.end();

  removeOriginalSubkey: () ->
    args = @defArgs.concat ["--delete-secret-key", "#{@email}"]
    callGPG("#{@passphrase}\ny\n\y", args)

  importSubkeys: (location) ->
    args = @defArgs.concat ["--import", location]
    callGPG("#{@passphrase}", args)

module.exports = usableGPG
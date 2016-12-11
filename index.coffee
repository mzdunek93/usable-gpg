# dependent on native gpg v1.*
gpg = require 'gpg'
{ Promise } = require 'bluebird'
fs = require 'fs'
        
class usableGPG 
  constructor: (@opts = {}) ->
    @defArgs = ["--no-batch", "--passphrase-fd", "0", "--command-fd", "0"]
    if @opts.keyLocation
      @defArgs = ["--no-default-keyring", "--secret-keyring", "#{@opts.keyLocation}.sec", "--keyring", "#{@opts.keyLocation}.pub"].concat(@defArgs)

  callGPG = (input, args) ->
    console.log(input, args)
    new Promise (resolve, reject) ->
      gpg.call input, args, (err, res) ->
        if err 
          reject(err)
        else
          resolve(res)
    
  createKey: (keyType, keyLength, subkeyType, subkeyLength, expireDate) -> 
    key = \
      "Key-Type: #{keyType}\nKey-Length: #{keyLength}\nSubkey-Type: #{subkeyType}\nSubkey-Length: #{subkeyLength}\nName-Real: #{@opts.fullName}\nName-Comment: nope\nName-Email: #{@opts.email}\nExpire-Date: #{expireDate}\nPassphrase: #{@opts.passphrase}"
    if @opts.keyLocation
      key += "\n%secring #{@opts.keyLocation}.sec\n%pubring #{@opts.keyLocation}.pub\n%commit\n"
    console.log(key)
    callGPG(key, ['-v', '--batch', '--gen-key'])

  strengthenHash: (hashType) ->
    args = @defArgs.concat ["--edit-key", "#{@opts.email}"]
    console.log(args)
    callGPG("#{@opts.passphrase} setpref #{hashType}\ny\nsave", args)

  addSubkey: (length) ->
    args = @defArgs.concat ["--edit-key", "#{@opts.email}", "addkey"]
    callGPG("#{@opts.passphrase}\n4\n#{length}\n0\ny\ny\nsave\n", args)

  generateRevKey: (location) ->
    args = @defArgs.concat ["--output", "#{location}.gpg-revocation-certificate", "--gen-revoke", "#{@opts.email}"]
    callGPG("#{@opts.passphrase}\ny\n1\n\ny\n", args)

  exportPrivateKey: (location) ->
    args = @defArgs.concat ["--export-secret-keys", "--armor", "#{@opts.email}"]
    callGPG("#{@opts.passphrase}", args).then (res) ->
      fs.writeFileSync("#{location}.private.gpg-key", res.toString());

  exportPublicKey: (location) ->
    args = @defArgs.concat ["--export", "--armor", "#{@opts.email}"]
    callGPG("#{@opts.passphrase}", args).then (res) ->
      fs.writeFileSync("#{location}.public.gpg-key", res.toString());

  exportSubkeys: (location) ->
    args = @defArgs.concat ["--export-secret-subkeys", "#{@opts.email}"]
    callGPG("#{@opts.passphrase}", args).then (res) ->
      wstream = fs.createWriteStream(location)
      wstream.write(res)
      wstream.end();

  removeOriginalSubkey: () ->
    args = @defArgs.concat ["--delete-secret-key", "#{@opts.email}"]
    callGPG("#{@opts.passphrase}\ny\n\y", args)

  importSubkeys: (location) ->
    args = @defArgs.concat ["--import", location]
    callGPG("#{@opts.passphrase}", args)

module.exports = usableGPG
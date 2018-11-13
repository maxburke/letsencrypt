### How to get a cert

Change the hosted zone in `./letsencrype-azuredns-hook/azure.hook.sh` to the correct hosted zone.

Change to the correct directory, set the `SPN_PASSWORD=<svc_letsencrypt_password>` environment variable, and run `./fetch.sh`

### How to get a cert with multiple SAN entries

These scripts work but they can be a little annoying when getting certs that have multiple SAN entries. If you are getting 403's when running `fetch.sh`, do this:

1. Open `certs/domains.txt` in a text editor. It should look something like this:

```
example.com example.com *.example.com
```

The first entry is the CN, the following are SANs. Remove all but the first SAN so that it looks like this:

```
example.com example.com
```

Run `./fetch.sh`. It should succeed. Add back the other SANs, one at a time and run `./fetch.sh` with each addition. If this fails, re-try and it should succeed. After you've done this you'll have a cert with multiple SANs. Yay!


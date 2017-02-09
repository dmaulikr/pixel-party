# Pixel Party
Multiplayer games played on your phone(s)!

## Development instructions
- Clone this repo
- Rename `Pixel Party/ENV.plist.sample` to `Pixel Party/ENV.plist`.
- Open `Pixel Party.xcworkspace`
- Run!
  
Note that Chromecast integration will NOT work out of the box. You'll need to update the `ChromecastAppId` key with a valid value (by registering a new Chromecast app with Google) and also do a bunch of additional work, including deploying a separate webapp to a publicly accessible URL. For now, this is beyond the scope of this README, but I may add instructions for it in the future.

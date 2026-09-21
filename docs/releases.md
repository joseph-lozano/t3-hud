# Build a signed DMG manually

The **Build signed DMG** workflow runs only from **Run workflow** in GitHub Actions. It builds an Apple Silicon app for macOS 13 or later, signs the app and DMG, submits the DMG to Apple for notarization, staples the ticket, and uploads the DMG plus a SHA-256 checksum. It does not create a GitHub Release. Artifacts expire after 30 days.

## One-time setup

You need an active Apple Developer Program membership and access to a Developer ID Application certificate with its private key.

1. Commit and push the workflow, scripts, and docs to the default branch. GitHub requires the workflow there before its manual trigger appears.
2. In **Xcode → Settings → Apple Accounts**, select your developer team, open **Manage Certificates**, and create or locate a **Developer ID Application** certificate. Use the same certificate as your local signed builds if possible. An Apple Development or Developer ID Installer certificate is not a substitute.
3. In **Keychain Access → My Certificates**, locate that certificate and expand it to confirm its private key is present. Export that one identity as a `.p12`, including its private key, and set a strong export password. Keep the export outside this repository.
4. Copy its encoded contents to the clipboard, substituting the actual path:

   ```sh
   base64 -i "$HOME/Desktop/T3-HUD-signing.p12" | pbcopy
   ```

5. Open [repository Actions secrets](https://github.com/joseph-lozano/t3-hud/settings/secrets/actions). Under **Repository secrets**, use **New repository secret** for each entry below. Paste credentials directly into GitHub, not into chat or source files.

   | Secret | Value |
   | --- | --- |
   | `MACOS_CERTIFICATE_BASE64` | Clipboard contents from the `.p12` export |
   | `MACOS_CERTIFICATE_PASSWORD` | Password chosen when exporting the `.p12` |
   | `APPLE_ID` | Apple Account email belonging to the developer team |
   | `APPLE_TEAM_ID` | Team ID in your [developer account membership details](https://developer.apple.com/account) |
   | `APPLE_APP_PASSWORD` | App-specific password created below |

6. At [account.apple.com](https://account.apple.com), open **Sign-In and Security → App-Specific Passwords**, generate a password named `T3 HUD GitHub Actions`, and put it in `APPLE_APP_PASSWORD`. This requires two-factor authentication. Use the generated password, not your normal Apple Account password.

The runner generates its temporary keychain password and selects the imported identity. No signing-identity secret or provisioning profile is needed for this app's current configuration. The workflow deletes its keychain at the end; GitHub also discards the hosted runner. Run the signing workflow only against trusted code because that code receives access to release credentials.

## Each build

1. Open [Actions](https://github.com/joseph-lozano/t3-hud/actions) and select **Build signed DMG**.
2. Click **Run workflow**, select the branch to build, and enter a version such as `0.1.1`. Use three numeric components without a `v` prefix. The Actions run number supplies the build number; the bundle identifier stays unchanged.
3. Start the workflow and wait for all steps to pass. It waits up to 30 minutes for notarization. A timed-out submission may still finish at Apple, but that run does not upload an artifact.
4. Open the successful run and download `T3-HUD-<version>-arm64` under **Artifacts**. Unzip it to obtain the DMG and checksum.
5. In the extracted directory, check the download, substituting your version:

   ```sh
   shasum -a 256 -c T3-HUD-0.1.1.dmg.sha256
   xcrun stapler validate T3-HUD-0.1.1.dmg
   ```

6. Quit the current HUD, open the DMG, drag the app to Applications, and launch it normally from Finder. The DMG shortcut installs to `/Applications`; the development install script uses `~/Applications`. Avoid keeping two copies when testing. Check connection, hotkey, and alerts. Prefer a separate Mac or user account for the first distribution check.

The workflow checks the Apple Silicon executable architecture, signatures, Apple's acceptance, the stapled ticket, and Gatekeeper's DMG assessment. It does not launch the authenticated app or prove its UI behavior. Notarization does not establish that T3 still accepts an existing session.

## Troubleshooting

- **Workflow missing:** confirm it is on the default branch and Actions is enabled.
- **Missing identity:** export the certificate with its private key and confirm it is a valid Developer ID Application identity. The workflow expects exactly one.
- **Authentication failure:** check the Apple ID, team membership, team ID, and app-specific password. Apple account agreements may need acceptance in the developer portal.
- **Notarization rejected:** the step prints its submission ID. Fetch Apple's log locally with `xcrun notarytool log <submission-id> --apple-id <email> --team-id <team-id>`; the tool prompts for the app-specific password.

For a local packaging check, run `./scripts/build` then `./scripts/package-dmg`. Set `T3HUD_ARCH=arm64`, `T3HUD_VERSION`, and `T3HUD_BUILD_NUMBER` on the build command to match CI. Set `T3HUD_SIGNING_IDENTITY` on both commands for certificate signing. Local packaging alone does not notarize the DMG.

References: [GitHub certificate import](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications), [Apple Developer ID and notarization](https://developer.apple.com/developer-id/), [Apple app-specific passwords](https://support.apple.com/en-us/102654).

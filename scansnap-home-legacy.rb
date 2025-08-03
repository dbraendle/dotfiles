cask "scansnap-home-legacy" do
  version "2.22.0"
  sha256 "a1b2c3d4e5f6"  # Will need to be updated with actual SHA256

  url "https://www.pfu.ricoh.com/global/scanners/scansnap/dl/setup/m-sshoffline-#{version.dots_to_underscores}.dmg"
  name "ScanSnap Home Legacy"
  desc "Fujitsu ScanSnap Scanner software (legacy version for Apple Silicon)"
  homepage "https://www.pfu.ricoh.com/global/scanners/scansnap/"

  pkg "ScanSnap Home.pkg"

  uninstall pkgutil: "jp.co.pfu.ScanSnapHome"
end
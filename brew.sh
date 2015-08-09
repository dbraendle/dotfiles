#!/bin/bash

# Check for Homebrew, Install if we don't have it
if test ! $(which brew); then
	echo "Installing homebrew..."
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Make sure we’re using the latest Homebrew
echo "updating brew"
brew update

# Upgrade any already-installed formulae
echo "upgrading brew formulae"
brew upgrade


brewApps=(
	coreutils
	moreils
	findutils
	gnu-sed --with-default-names
	wget --with-iri
	grc
	ack
	git
	imagemagick --with-webp
	node
	pv
	rename
	tree
	ffmpeg --with-libvpx
	mackup
	caskroom/cask/brew-cask
)

brew tap homebrew/versions

echo "installing brew apps …"
brew  install ${brewApps[@]}

brewCaskApps=(
	#Produktivität
	alfred
	dropbox	
	things
	istat-menus
	skype
	teamviewer
	gpgtools
	grandtotal
	evernote

	##Arbeitstools
	adobe-creative-cloud
	sublime-text3 
	transmit
	github
	virtualbox
	imageoptim
	codekit

	#gehasst, aber noch notwendig
	flash
	silverlight
	java

	
	#Media
	vlc
	jdownloader2


	#System
	appcleaner
	qlcolorcode


	# browsers
	google-chrome
	firefox
	google-chrome-canary
	firefox-nightly --force
	webkit-nightly --force
	chromium --force
	torbrowser
)

brew tap caskroom/versions

echo "installing brew cask apps …"
brew cask install --appdir="/Applications" ${brewCaskApps[@]}
echo "cleaning up …"
brew cask cleanup

fonts=(
	font-open-sans
	font-open-sans-condensed
	font-railway
	font-varela-round
	font-font-awesome
	font-titillium
)

brew tap caskroom/fonts

echo "installing fonts..."
brew cask install ${fonts[@]}
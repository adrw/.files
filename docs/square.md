## Square Setup

```
$ ./bootstrap.sh -p mac_square -r -b /usr/local -v -s adrw
```

## Steps

- Use quick start command from README to run bootstrap with the above options
- Follow steps in go/ssh to create new SSH key, and add to Bitbucket, Github, and Registry
- Rerun bootstrap which now should succeed (especially for the Square specific parts that require Bitbucket access)
- Run `$ babushka cacerts java mysql`
- Manually import square-primary-g2 cert
  - `cd ~/.babushka/deps/cacerts`
  - `sudo keytool -import -noprompt -storepass changeit -cacerts -alias square-service-authority -file square-primary-g2.pem`
  - The presence of the certificate can be verified using the keytool:
    `keytool -list -v -storepass changeit -keystore '/Library/Java/JavaVirtualMachines/<JRE/JDK>/Contents/Home/lib/security/cacerts' | grep 'SHA1: 02:8C:D8:2A:FC:79:3D:18:83:80:DF:48:1C:5F:F3:D1:72:A0:69:C1'`
- Install `rvm` [instructions](https://rvm.io/)
  ```
  gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  \curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
  rvm install 2.6
  rvm use --default 2.6
  ```
- Install `config_files` to get all default Square CLI tools, Ruby Gems, and configuration
- Manuall download Mac App Store apps (Byword, Affinity, Microsoft Office...)
- polyrepo
  - polyrepo init
  - polyrepo add ...
  - Import project into IntelliJ
- Setup Yubikey
  - `go/yubikey`

## Steps to Automate

- In `config_files`, run the following to get all necessary Ruby Gems installed
  ```
  $ brew install curl
  $ gem install bundler:2.0.1
  $ bundle install
  ```
- Add key to support Github Squareup `cp ~/Development/config_files/ssh/pkcs11.dylib ~/.ssh/`

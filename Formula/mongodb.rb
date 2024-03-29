require 'formula'

class Mongodb < Formula
  homepage 'http://www.mongodb.org/'

  if Hardware.is_64_bit? and not ARGV.build_32_bit?
    url 'http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-1.8.1.tgz'
    md5 'e446ba61cc8898fa2ffd5046953155ca'
    version '1.8.1-x86_64'
  else
    url 'http://fastdl.mongodb.org/osx/mongodb-osx-i386-1.8.1.tgz'
    md5 'db95a601072feb3031f628dd39ca2446'
    version '1.8.1-i386'
  end

  skip_clean :all

  def options
    [['--32-bit', 'Build 32-bit only.']]
  end

  def install
    # Copy the prebuilt binaries to prefix
    prefix.install Dir['*']

    # Create the data and log directories under /var
    (var+'mongodb').mkpath
    (var+'log/mongodb').mkpath

    # Write the configuration files and launchd script
    (prefix+'mongod.conf').write mongodb_conf
    plist_path.write startup_plist
    plist_path.chmod 0644

    # copy the config file to etc if this is the first install.
    etc.install prefix+'mongod.conf' unless File.exists? etc+"mongod.conf"
  end

  def caveats; <<-EOS.undent
    If this is your first install, automatically load on login with:
        mkdir -p ~/Library/LaunchAgents
        cp #{plist_path} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    If this is an upgrade and you already have the #{plist_path.basename} loaded:
        launchctl unload -w ~/Library/LaunchAgents/#{plist_path.basename}
        cp #{plist_path} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    Or start it manually:
        mongod run --config #{etc}/mongod.conf

    The launchctl plist above expects the config file to be at #{etc}/mongod.conf.
    EOS
  end

  def mongodb_conf; <<-EOS.undent
    # Store data in #{var}/mongodb instead of the default /data/db
    dbpath = #{var}/mongodb

    # Only accept local connections
    bind_ip = 127.0.0.1
    EOS
  end

  def startup_plist
    return <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>#{plist_name}</string>
  <key>ProgramArguments</key>
  <array>
    <string>#{HOMEBREW_PREFIX}/bin/mongod</string>
    <string>run</string>
    <string>--config</string>
    <string>#{etc}/mongod.conf</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>UserName</key>
  <string>#{`whoami`.chomp}</string>
  <key>WorkingDirectory</key>
  <string>#{HOMEBREW_PREFIX}</string>
  <key>StandardErrorPath</key>
  <string>#{var}/log/mongodb/output.log</string>
  <key>StandardOutPath</key>
  <string>#{var}/log/mongodb/output.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>TZ</key><string>UTC</string>
  </dict>
</dict>
</plist>
EOS
  end
end

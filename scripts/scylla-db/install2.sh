echo "[INFO] Ensuring apt-utils is installed..."
sudo apt-get update
sudo apt-get install -y apt-utils

echo "[INFO] Removing old ScyllaDB repository files..."
sudo rm -f /etc/apt/sources.list.d/scylla*.list

echo "[INFO] Adding ScyllaDB repository for Ubuntu..."
curl -s -L https://repositories.scylladb.com/scylla/repo/0de3e5d067167ebe832f17671ff55e78/ubuntu/scylladb-5.2.list | sudo tee /etc/apt/sources.list.d/scylla.list

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to download ScyllaDB repository file."
    exit 1
fi

echo "[INFO] Verifying repository file..."
if [ ! -s /etc/apt/sources.list.d/scylla.list ]; then
    echo "[ERROR] ScyllaDB repository file is empty or missing."
    exit 1
fi
cat /etc/apt/sources.list.d/scylla.list

echo "[INFO] Updating apt cache..."
sudo apt-get update

echo "[INFO] Installing wget..."
sudo apt-get install -y wget

echo "[INFO] Installing ScyllaDB..."
sudo apt-get install -y scylla
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to install ScyllaDB."
    exit 1
fi

echo "[INFO] Running ScyllaDB setup..."
sudo /usr/lib/scylla/scylla_setup --no-raid-setup --no-sysconfig-setup
if [ $? -ne 0 ]; then
    echo "[ERROR] ScyllaDB setup failed."
    exit 1
fi

echo "[INFO] Enabling ScyllaDB service..."
sudo systemctl enable scylla-server
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to enable scylla-server service."
    exit 1
fi

echo "[INFO] Starting ScyllaDB service..."
sudo systemctl start scylla-server
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to start scylla-server service."
    exit 1
fi

echo "[INFO] Checking ScyllaDB status..."
sudo systemctl status scylla-server
sudo nodetool status

echo "[INFO] ScyllaDB installation and startup complete."

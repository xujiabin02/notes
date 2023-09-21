

# vscode web 版本





```sh
wget https://github.com/coder/code-server/releases/download/v4.12.0/code-server_4.12.0_amd64.deb
sudo apt install ./code-server_4.12.0_amd64.deb 
sudo systemctl enable code-server@appuse
# vi ~/.config/code-server/config.yaml
sudo systemctl start code-server
sudo systemctl status code-server
```




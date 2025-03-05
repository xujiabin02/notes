- Server poll timeout, trying next remote entry...

- 注释dns拦截

  - ```
    	  #setenv opt block-outside-dns # Prevent Windows 10 DNS leak
    ```

- 开启内核转发

  - ```
    	  cat /proc/sys/net/ipv4/ip_forward
    	  或 sysctl -w net.ipv4.ip_forward = 1
    ```

- server ip pool 更改, iptables nat也要改

  - ```
    	  -A POSTROUTING -s 10.18.0.0/24 -o eth0 -j MASQUERADE
    	  -A POSTROUTING -s 192.168.2.0/24 -o tun1 -j MASQUERADE
    	  -A POSTROUTING -s 10.8.0.0/24 -o enp129s0f0 -j MASQUERADE
    	  -A POSTROUTING -o tun1 -j MASQUERADE    # 这行,成功
    	  # 待测试
    	  -A INPUT -i tun1 -j ACCEPT
    	  -A FORWARD -i tun1 -o enp129s0f0 -j ACCEPT
    	  -A FORWARD -i enp129s0f0 -o tun1 -j ACCEPT
    	  
    	  
    ```

- 配置log

  - ```
    	  log-append /var/log/openvpn/openvpn.log 
    ```
# EasyTier Docker

[![Release](https://github.com/MajoSissi/easytier-docker/actions/workflows/release.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/release.yml)
[![Pre-release](https://github.com/MajoSissi/easytier-docker/actions/workflows/pre.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/pre.yml)

[EasyTier](https://github.com/EasyTier/EasyTier) 发布新版本时，自动构建并发布 Docker 镜像

## Docker Compose 使用方法

### 完整版 ( Core组网 + Web控制台 )

<!-- BEGIN_COMPOSE_CORE -->
```yaml
# Core + Web 控制台一体部署
# 镜像说明: https://hub.docker.com/r/majosissi/easytier
services:
  easytier:
    # 可选镜像
    # majosissi/easytier:latest  最新发布正式版
    # majosissi/easytier:pre     最新 Action 构建版 (合并主线的版本, 自动更新, 稳定性不保证)
    image: majosissi/easytier:latest
    container_name: easytier
    restart: always
    network_mode: host
    environment:
      # 时区
      - TZ=Asia/Shanghai
      # 远程 Web 服务 URL, 直接连接远程控制台
      # 设置后会忽略 WEB_USERNAME, 不可同时连接多个 Web, 但仍可启用本地控制台
      # 示例: udp://api.web.com:22020/username
      # 默认: 无
      # - WEB_REMOTE_API=协议://主机:端口/用户名
      # 是否启用 Web 管理界面
      # 默认: false
      - WEB_ENABLE=true
      # Web 管理用户名; 设置 WEB_REMOTE_API 时此项无效
      # 启用 Web 且提供用户名时将自动连接本地控制台, 仍需在界面注册该用户 (不使用 admin/root)
      # 默认: 无
      - WEB_USERNAME=修改为你的用户名
      # Web 前端默认连接的后端 API HOST
      # 默认: http://127.0.0.1:11211
      - WEB_DEFAULT_API_HOST=http://修改为你的主机:11211
      # Web 前端访问端口
      # 默认: 11211
      - WEB_PORT=11211
      # Web 后端 API 监听端口; 可与前端复用
      # 默认: 11211
      - WEB_API_PORT=11211
      # Web 管理服务 (RPC) 监听端口, Core 将通过此端口连接
      # 默认: 22020
      - WEB_SERVER_PORT=22020
      # Web 管理服务 (RPC) 协议, 可与其他节点的 -w 参数保持一致
      # 默认: udp - 可选: [udp | tcp | ws]
      - WEB_SERVER_PROTOCOL=udp
      # Web 服务日志级别 
      # 默认: warn - 可选: [off | error | warn | info | debug | trace] 
      - WEB_LOG_LEVEL=warn
      # Web 数据目录, 存放 (数据库/日志/机器码)
      # 默认: /web
      - WEB_DATA_DIR=/web
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ./web:/web
      # 配置文件目录可自定义 (非必要, 除非用配置文件运行)
      # - ./config:/config
    # 如果启用了 Web 且设置了用户名, 不用设置 command, 直接用 Web 控制台管理
    # command 为 easytier-core 命令的参数
    # command: -i 10.126.126.1 --network-name my-network --network-secret my-secret -p 节点服务器
```
<!-- END_COMPOSE_CORE -->

### 仅Web版 ( Web控制台 )

<!-- BEGIN_COMPOSE_WEB -->
```yaml
# 单 Web 控制台部署
# 镜像说明: https://hub.docker.com/r/majosissi/easytier-web
services:
  easytier-web:
    # majosissi/easytier-web:latest 最新发布正式版
    # majosissi/easytier-web:pre 最新 Action 构建版 (合并主线的版本, 自动更新, 稳定性不保证)
    image: majosissi/easytier-web:latest
    container_name: easytier-web
    restart: always
    network_mode: bridge
    ports:
      - 11211:11211
      - 22020:22020
    environment:
      # 时区
      - TZ=Asia/Shanghai
      # Web 前端默认连接的后端 API HOST
      # 默认: http://127.0.0.1:11211
      - WEB_DEFAULT_API_HOST=http://修改为你的主机:11211
      # Web 前端访问端口
      # 默认: 11211
      - WEB_PORT=11211
      # Web 后端 API 监听端口; 可与前端复用
      # 默认: 11211
      - WEB_API_PORT=11211
      # Web 管理服务 (RPC) 监听端口, Core 将通过此端口连接
      # 默认: 22020
      - WEB_SERVER_PORT=22020
      # Web 管理服务 (RPC) 协议, 可与其他节点的 -w 参数保持一致
      # 默认: udp - 可选: [udp | tcp | ws]
      - WEB_SERVER_PROTOCOL=udp
      # Web 服务日志级别 
      # 默认: warn - 可选: [off | error | warn | info | debug | trace] 
      - WEB_LOG_LEVEL=warn
      # Web 数据目录, 存放 (数据库/日志/机器码)
      # 默认: /web
      - WEB_DATA_DIR=/web
    volumes:
      - ./web:/web
```
<!-- END_COMPOSE_WEB -->

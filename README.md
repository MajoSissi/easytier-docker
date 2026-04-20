# EasyTier Docker

[![Release](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-release.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-release.yml)
[![Pre-release](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-pre.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-pre.yml)
[![CI](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-ci.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/build-ci.yml)

[EasyTier](https://github.com/EasyTier/EasyTier) 发布新版本时，自动构建并发布 Docker 镜像

## Compose

<!-- BEGIN_COMPOSE_CORE -->
```yaml
# Core + Web 控制台一体部署
# 镜像说明: https://hub.docker.com/r/majosissi/easytier
services:
  easytier:
    # majosissi/easytier:latest  最新 Release 正式版
    # majosissi/easytier:pre     最新 Pre-release 预览版
    # majosissi/easytier:ci      最新 Action 构建版 (合并主线的版本, 自动更新, 稳定性不保证)
    image: majosissi/easytier:latest
    container_name: easytier
    restart: always
    # 限制容器输出日志的大小和数量, 建议启用
    logging:
      driver: "json-file"
      options:
        # 单个日志文件的最大大小  
        max-size: "10m"
        # 最多保留的日志文件数量
        max-file: "3"
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      # -------------------------------------------
      # 自定义节点主机名, 可用于 Web 控制台显示和区分不同节点
      # 默认: 无
      # - HOSTNAME=node1
      # -------------------------------------------
      # 连接其他远程 Web 控制台
      # 设置后会忽略 WEB_USERNAME, 不可同时连接多个 Web, 但仍可启用本地控制台
      # 示例: udp://api.web.com:22020/username
      # 默认: 无
      # - WEB_REMOTE_API=协议://主机:端口/用户名
      # -------------------------------------------
      # 是否启用 Web 管理界面 
      # 默认: false
      - WEB_ENABLE=false
      # -------------------------------------------
      # 是否允许注册新用户 (内置用户: admin, 密码: admin, 登录后右上角可修改密码)
      # 默认: false
      - WEB_ENABLE_REGISTRATION=false
      # -------------------------------------------
      # Web 管理用户名; 设置 WEB_REMOTE_API 时此项无效
      # 启用 Web 且提供用户名时将自动连接本地控制台
      # 自定义用户名，需要先手动注册对应用户名才行 
      # 默认: 无
      - WEB_USERNAME=admin
      # -------------------------------------------
      # 主机物理IP地址 (公网 / 内网)
      # 默认: http://127.0.0.1:11211
      - WEB_DEFAULT_API_HOST=http://修改为你的主机:11211
      # -------------------------------------------
      # Web 访问端口
      # 默认: 11211
      - WEB_PORT=11211
      # -------------------------------------------
      # Web 管理服务 (RPC) 监听端口, Core 将通过此端口连接
      # 默认: 22020
      - WEB_SERVER_PORT=22020
      # -------------------------------------------
      # Web 管理服务 (RPC) 协议, 可与其他节点的 -w 参数保持一致
      # 默认: udp - 可选: [udp | tcp | ws]
      - WEB_SERVER_PROTOCOL=udp
      # -------------------------------------------
      # Web 服务日志级别 
      # 默认: warn - 可选: [off | error | warn | info | debug | trace] 
      - WEB_LOG_LEVEL=error
      # -------------------------------------------
      # Core 服务日志级别
      # 默认: warn - 可选: [ error | warn | info | debug | trace]
      - CORE_LOG_LEVEL=error
      # -------------------------------------------
      # GeoIP 数据库文件路径 (可在 Web 控制台显示地理位置信息)
      # 推荐: https://github.com/P3TERX/GeoLite.mmdb/releases (建议放到放到映射的目录 ./data/web 下, 记得更改对应文件名称/路径)
      # 默认: 无
      # - WEB_GEOIP_PATH=/app/data/web/GeoLite2-City.mmdb
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ./data:/app/data
      # 将写好的配置文件放在 ./data/config 下每个文件都是一个实例(.toml格式), 会跟着容器一起启动/运行
```
<!-- END_COMPOSE_CORE -->
# EasyTier Docker

[![Build EasyTier release Docker Image](https://github.com/MajoSissi/easytier-docker/actions/workflows/release.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/release.yml)
[![Build EasyTier Pre-release Docker Image](https://github.com/MajoSissi/easytier-docker/actions/workflows/pre.yml/badge.svg)](https://github.com/MajoSissi/easytier-docker/actions/workflows/pre.yml)

本项目包含一个 GitHub Action 工作流，用于在 [EasyTier](https://github.com/EasyTier/EasyTier) 发布新版本时，自动构建并发布 Docker 镜像到 DockerHub。

## 配置方式

如果你想自己部署这套构建流程，请按以下步骤操作：

1. **Fork 本仓库**：点击右上角的 "Fork" 按钮将本项目复制到你的 GitHub 账号下。
2. **配置 Secrets**：
   进入你 Fork 后的仓库设置页面：`Settings` -> `Secrets and variables` -> `Actions`，点击  `Newrepository secret` 添加以下两个密钥：
   * `DOCKERHUB_USERNAME`: 你的 DockerHub 用户名。
   * `DOCKERHUB_TOKEN`: 你的 DockerHub Access Token
3. **启用 Actions**：
   进入 `Actions` 标签页，如果看到提示，请点击启用 GitHub Actions。
4. **权限设置**：
    确保 Workflow 有权限写入仓库（为了更新 `LAST_VERSION` 文件）。通常在 `Settings` -> `Actions` -> `General` -> `Workflow permissions` 中选择 `Read and write permissions`。

配置完成后，工作流将自动按计划运行。你也可以在 `Actions` 页面手动触发 `Build EasyTier release Docker Image` 工作流进行测试。

## Docker 使用方法

请参考仓库中的 [Docker Compose](docker-compose.yaml) 文件。

### 启动参数说明

Docker 容器启动时传递的参数（`command` 部分）将直接传递给 `easytier-core`。

例如：
```bash
command: -i 10.144.144.1 --network-name my-network --network-secret my-secret -p 节点服务器
```
等同于在命令行运行 `easytier-core -i 10.144.144.1 ...`。

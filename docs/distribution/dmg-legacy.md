# DMG 安装与发布说明

Codex Toolbox v1.0.0 同时提供 PKG 和 DMG。PKG 是从 Show Codex IQ 升级的推荐选择；DMG 供偏好拖拽安装的用户选择。

## DMG 升级限制

DMG 不能自动删除改名前的 `/Applications/Show Codex IQ.app`。升级用户需要先退出并删除旧应用，再把 `Codex Toolbox.app` 拖入 Applications。这项提醒会同时出现在 DMG 背景、内附文档、README 和 Release Notes 中。

## 构建与公证

```text
build_dmg.sh → package_dmg.sh → verify_dmg.sh → notarize_dmg.sh
```

DMG 内的应用和 DMG 本身使用 Developer ID Application 签名，随后通过 Apple 公证、staple 和 Gatekeeper 验证。没有正式证书时构建的 ad-hoc DMG 只能用于本机布局与启动测试，不是 Release 附件。

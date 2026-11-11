# 本地编辑器连接与视觉检查

本目录只保留通用 MCP 连接器。Windows 本地开发连接已经打开的 Godot 编辑器；云端使用 tools/cloud，不尝试本机端口。按开发指南捕获新鲜现场并隔离测试存档，不能重放历史恢复脚本。

school_mcp.mjs 导出 connect/call/client/expression/click/key/capture。连接器从项目 node_modules 或当前用户 npm 缓存查找已经安装的 Godot MCP server，也可用 GODOT_MCP_SERVER_ENTRY 指定其 dist/index.js。不提交机器路径或凭据，不自动安装依赖或打开第二个编辑器。capture 默认输出被忽略的 .godot/visual-review。

mcp_client.mjs list [正则] 查询工具；mcp_client.mjs 请求.json 执行标准 MCP {name, arguments} 请求或数组。与编辑器使用相同的 APPDATA/LOCALAPPDATA；连接由现有编辑器插件授权。执行会修改现场的命令前核对请求内容。

当前可重复回归位于 tools/tests，跨平台隔离运行器为 tools/run_godot_tests.py。测试使用真实自动加载、生产场景、Viewport 输入和独立存档；截图默认仅保留本机。

132个历史阶段脚本已从当前工作树移除，清单、SHA256和Git恢复基线见 [ARCHIVE.json](../../docs/2026-10-25/ARCHIVE.json)。它们依赖旧节点、固定日期或旧状态，不能作为当前恢复器。历史文档提及这些路径时，从清单指定提交查看，不直接重放。

# payload\ —— 需要你自己准备的补丁文件

这个目录里的东西会**原样复制到游戏目录**，所以必须保持和游戏目录一致的相对路径。

本仓库不包含这些文件：Fallout 1 的代码与资源 © Bethesda Softworks / Interplay；
简体中文文本、`fallout_font.dll` 与汉化主程序 © **13 号避难所《异尘余生汉化包》** 的各位作者
（程序 **noword**，译者名单见[仓库首页致谢](../README.md#致谢)）；`f1_res` 高清补丁 © Mash (Matt Wells)。
把它们提交到公开仓库有被 DMCA 下架的风险，所以只提供结构和校验清单。

## 需要哪些文件（共约 750 个，8.08 MB）

| 路径 | 说明 |
|---|---|
| `FALLOUTW.EXE` | 汉化主程序，1,245,696 字节，内含 2007 年的字体 DLL 加载器（`.topo0` 段），必须是这个版本 |
| `fallout_font.dll` | GBK 中文点阵字体，启动器要注入的就是它；SHA256 应为 `9E9211F0…88650A`（与上游归档逐字节一致） |
| `ddraw.dll` `f1_res.dll` | f1_res 高清补丁渲染层 |
| `f1_res.ini` | f1_res 配置；安装脚本会改写 `path=` / 分辨率等字段，随便一份能用的即可 |
| `f1_res_Config.exe` `f1_res_patcher.exe` `f1_res_README.rtf` | f1_res 自带的配置/安装工具与说明 |
| `Fallout_chinese_windowed.cmd` `fallout_chinese_windowed.ps1` | 窗口/全屏启动器（负责注入字体 DLL、调窗口尺寸、退出恢复 ini） |
| `Fallout_chinese.cmd` `fallout_chinese.ps1` | 后备启动器（基本模式全屏） |
| `fallout.ico` | 快捷方式图标 |
| `DATA\TEXT\ENGLISH\**` | 696 个中文 `.MSG` / `.TXT`：`DIALOG\`（620 个对话）、`GAME\`（46 个界面/物品）、`CUTSCENE\`（27 个字幕）等 |
| `DATA\art\intrface\**` | 38 个中文界面 `.FRM`（按钮、菜单字） |
| `DATA\premade\**` | 3 个角色预设 `.GCD` |
| `DATA\sound\`（可选） | 如果汉化补丁带中文字幕音轨，一并放进来 |

`master.dat` / `critter.dat` / `patch000.dat` **不需要**，也不应该放进 payload —— 汉化完全靠外部文件覆盖。

## 两个启动器脚本从哪来

`Fallout_chinese.cmd` / `fallout_chinese.ps1` / `Fallout_chinese_windowed.cmd` /
`fallout_chinese_windowed.ps1` **不是什么第三方文件**，就是这套启动器的源码：

- 如果你的机器上已经有能跑的中文 + 高清环境，直接从游戏目录把这四个文件复制过来；
- 或者从本仓库自己的一份安装里取回（它们和游戏目录里的那份内容完全一致）。

缺少它们的话，`install.cmd` 装完游戏能跑中文，但没有窗口化 / DX9 渲染，
而且直接启动会因为字体 DLL 没预加载而崩（见 [`../docs/technical.md`](../docs/technical.md)）。

## 校验

`docs/payload-manifest.txt` 记录了参考安装里全部文件的相对路径和 SHA256。
准备好 payload 之后可以逐条比对：

```powershell
# 逐行比对，输出不匹配的文件
Get-Content .\docs\payload-manifest.txt | ForEach-Object {
    if ($_ -match '^([0-9A-F]{64})  (.+)$') {
        $want = $matches[1]; $rel = $matches[2]
        $f = Join-Path .\payload $rel
        $got = if (Test-Path -LiteralPath $f) { (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash } else { 'MISSING' }
        if ($got -ne $want) { "$rel  want=$want  got=$got" }
    }
}
```

## 来源

中文部分的出处是 **13 号避难所（bn13.com）的《异尘余生汉化包》**：2007 年发布，程序 **noword**，
译者名单在[仓库首页致谢](../README.md#致谢)。原项目页 `code.google.com/p/falloutchs` 已经关站，
现在可以从 [zillionk/falloutchs](https://github.com/zillionk/falloutchs) 拿到归档 ——
其中的 `fallout_font.dll` 与参考安装的 SHA256 完全一致（`9E9211F0…88650A`），
可以用它核对版本对不对得上。

`f1_res` 高清补丁来自 Matt Wells (Mash) 的 Fallout High Resolution Patch，一直公开发布。

请只对你自己拥有的正版游戏使用，不要把 `payload\` 提交进公开仓库；
原汉化包明确要求「未经许可，请勿用于任何商业目的」。

# Fallout 1 简体中文 + 高清分辨率补丁包（Steam 版）

把 Steam 正版 **Fallout 1**（appid 38400，`steamapps\common\Fallout`）一键变成
「简体中文 + 2560×1440 可移动窗口」的版本，并且**卸载能把每个被覆盖的原版文件
还原成一模一样的字节**（SHA256 校验通过）。

补丁本体只有 **8 MB**：中文化是通过外部文件覆盖实现的，`master.dat` 没有被改动，
所以不需要重下 500 MB 的游戏数据。

```
双击 install.cmd  →  桌面出现两个快捷方式  →  开玩
```

---

## 特性

| | |
|---|---|
| **自动找游戏** | 读注册表 `SteamPath` + 解析 `libraryfolders.vdf` + 扫常见盘符；装在非 C 盘、多 Steam 库都能找到，也可 `-GameDir "路径"` 手动指定 |
| **幂等安装** | 每个文件按 SHA256 比对，内容相同就跳过；重复运行不会刷出一堆备份，也不会重写已正确的 ini |
| **可回滚** | 覆盖前备份到 `backup\<时间戳>\` 并写 `manifest.json`（记录每个文件原来是否存在），卸载完全按清单还原 |
| **路径无关** | `f1_res.ini` 里的 `path=` 会改写成实际安装位置，换盘、换机器、换用户名都不会指错 |
| **不误伤别的存档** | `%APPDATA%\Fallout\<hash>\f1_res.ini` 只有在它自己的 `path=` 指向本游戏时才被改 |
| **安全出口** | 安装后 ini 停在「基本模式 1920×1440 全屏」，所以即使直接点 Steam 的「开始游戏」也是能玩的中文版 |
| **不杀进程** | 检测到安卓模拟器只提示，不擅自结束 |

## 目录结构

```
.
├─ install.cmd            双击安装
├─ uninstall.cmd          双击卸载
├─ README.txt             给最终用户看的说明（会打进补丁包里）
├─ build-release.ps1      用 payload\ 打出一个可直接分发的 zip
├─ tools\
│  ├─ install.ps1         安装逻辑（备份 / 复制 / ini / 快捷方式）
│  └─ uninstall.ps1       卸载逻辑（按 manifest.json 还原）
├─ payload\               汉化 + 高清补丁的原始文件（不入库，见 payload\README.md）
└─ docs\
   ├─ technical.md        为什么需要启动器注入字体 DLL、两份 ini 是怎么回事
   └─ publish.md          把这个仓库发到 GitHub 的三种方式
```

`payload\` 里的内容按游戏目录的相对路径摆放，安装时原样复制过去：

```
payload\
  FALLOUTW.EXE                   汉化主程序（内含 noword 写的字体 DLL 加载器）
  fallout_font.dll               GBK 中文点阵字体（noword）
  ddraw.dll  f1_res.dll          hi-res 补丁 f1_res（Matt Wells / Mash）
  f1_res.ini  f1_res_Config.exe  f1_res_patcher.exe  f1_res_README.rtf
  Fallout_chinese_windowed.cmd   fallout_chinese_windowed.ps1    窗口/全屏启动器
  Fallout_chinese.cmd            fallout_chinese.ps1             后备启动器
  fallout.ico
  DATA\TEXT\ENGLISH\...          696 个中文 .MSG / .TXT
  DATA\art\intrface\...          38 个中文界面 .FRM
  DATA\premade\...               3 个角色预设 .GCD
```

## 快速开始

### 1. 准备 `payload\`

本仓库**不包含**汉化文件（版权原因，见 [版权与免责](#版权与免责)）。
把 `payload\` 按上面列出的结构填好 —— 来源、需要哪些文件、如何校验都在
[`payload/README.md`](payload/README.md)。

### 2. 打出补丁包（可选）

只想要脚本，直接把整个目录复制进游戏目录的 `_CN_HD_Pack\` 就行；
想做成给别人下载的 zip：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
# → Fallout1_CN_HD_Pack.zip（会打印体积和 SHA256）
```

### 3. 安装

```powershell
# 解压后双击，或：
install.cmd
install.cmd -GameDir "E:\SteamLibrary\steamapps\common\Fallout"
install.cmd -NoShortcuts
```

安装脚本会：备份将被覆盖的原版文件 → 复制 750 个文件 → 把 `f1_res.ini`
设成安全状态 → 在桌面建「Fallout 中文窗口」「Fallout 中文全屏」两个快捷方式。

### 4. 启动

双击桌面快捷方式。想换尺寸就改快捷方式「目标」末尾的参数：

```bat
-ClientWidth 1920 -ClientHeight 1080
-Exclusive -ClientWidth 2560 -ClientHeight 1440
```

### 5. 卸载

```powershell
uninstall.cmd
uninstall.cmd -Backup 20261124_015500   # 指定某次备份
uninstall.cmd -KeepShortcuts            # 保留桌面快捷方式
```

会从最近的备份还原被覆盖的文件、删掉新增的文件、清理空目录。

## 常见问题

**Steam 验证游戏文件完整性之后中文没了？**
验证会把英文原版 `FALLOUTW.EXE` 装回来，重跑一次 `install.cmd` 即可（备份目录不会被覆盖，先卸载后安装也行）。

**点 Steam 的「开始游戏」还是英文 / 没高清？**
Steam 启动的是 `falloutw.exe`，看不到启动器。高清窗口只能用桌面快捷方式；直接点 Steam 也能玩中文，但走的是基本模式（1920×1440 全屏、无 DX9 渲染）。

**游戏弹 `Failure initializing input devices.`**
安卓模拟器（MuMu / 雷电 / 夜神 / BlueStacks）抢占了 DirectInput，玩之前先关掉它们。安装脚本检测到会提示，但不会去结束你的进程。

**窗口是 640×480 或者启动就崩？**
说明字体 DLL 没被预先加载。f1_res 的 DX9 渲染器在 `fallout_font.dll` 就位前绘制文字会崩（`0xc0000005`，模块 unknown）。启动器做的就是提前把 DLL 注入进去，看到 `fallout_font.dll pre-loaded, IAT filled.` 才算成功；失败时它会把进程结束并提示改用 `Fallout_chinese.cmd`。

**杀毒软件拦截启动器？**
启动器对游戏进程做 `CreateRemoteThread` 注入来预加载字体 DLL，行为上像外挂。需要放行 `powershell.exe` 执行 `fallout_chinese_windowed.ps1`。

**PowerShell 报「禁止运行脚本」？**
`.cmd` 已经带了 `-ExecutionPolicy Bypass`，直接双击不会有这个问题；手动跑 `.ps1` 才需要加参数。

**换机器后卸载报「找不到游戏目录」？**
`uninstall.cmd -GameDir "新路径"`，或者直接删掉 `_CN_HD_Pack\` 再让 Steam 验证完整性。

**支持 GOG / 原版光盘版吗？**
没测过。脚本只校验 `master.dat` + `falloutw.exe` 是否存在，理论上能用，但备份/还原是按 Steam 目录结构做的，自行评估。

## 技术说明

细节在 [`docs/technical.md`](docs/technical.md)：为什么必须注入、`0x0053CFC0` 是什么、为什么要同时处理游戏目录和 `%APPDATA%` 两份 `f1_res.ini`、`UAC_AWARE` / `GRAPHICS_MODE` / `path=` 各自的作用。

## 已测试

- Windows 11 + Steam 版 Fallout 1（appid 38400），装在 `D:\SteamLibrary`
- 假游戏目录端到端：安装 → 卸载 → 全部文件 SHA256 与安装前一致，空目录清理干净，真实 `%APPDATA%` ini 未被误改
- 真实目录：安装 750 文件、二次运行显示 `copied 0, already up to date 750`
- 启动器：注入成功、窗口标题 `Fallout @2560x1440x1`、退出后两份 ini 都回到 `GRAPHICS_MODE=0 / 1920×1440 / WINDOWED=0`

## 致谢

这个包里没有一行字是我翻的。中文来自 **13 号避难所（bn13.com）的《异尘余生汉化包》**，
2007 年由社区志愿者业余做完，**没有收过一分钱**。

- **程序**：**noword** —— `fallout_font.dll` 字体加载器、中英文切换、安装包，都是他写的
- **翻译**：老貓、蓝色◎流星、seanfx、西塞罗、失控的胖子、lspwjun（麻雀）、duwei、lbhzt（烟雨）、
  venom2000、anca_qin、NukeCoke、fabiocapello、asasass、noword、圆石陷阱、自由艺术家、小写的牧歌、
  sin、bean、laplace、zhaoxf62、天山七剑、wawbwc、无效指令、weizheng1129、nixcyx、夜叉狼、浪子小文、
  ducky热牛奶、rainboycn、Cyric、yuanyan、ChenZhuo、DoonerDie、necroman、bal、angelcat、darkhuang、
  Jedi、lonelyman、Dricimitar、wolfox、CAS、BAROCCO、prosup、AsTrAl、Sagonnas、硅光、Dutycalls
- **校对**：lbhzt（烟雨）、seanfx、murray、lspwjun（麻雀）、西塞罗、阴酆主人
- **「劳苦功高的超级苦力」**（原文如此）：老猫、阴酆主人
- **β 测试**：好大的棉花糖、烟雨、lwrt、pkhehe、蛾十三、woody、aribeth1999、murray
- **鸣谢**：炽天之翼、阴酆主人、刷锅、[bn13.com](http://www.bn13.com)、[ntrpg.org](http://www.ntrpg.org)、[tbsgame.net](http://tbsgame.net)

原 readme 注明：*排名不分先后*。

- **高清补丁**：Fallout High Resolution Patch © 2008–2014 **Matt Wells**（包里的 `f1_res.dll` /
  `f1_res_patcher.exe` 是 4.1.8）
- **原始游戏**：© Bethesda Softworks / Interplay

汉化包原来放在 Google Code 的 `code.google.com/p/falloutchs`（已关站），现在在
[zillionk/falloutchs](https://github.com/zillionk/falloutchs) 有归档；其中 `fallout_font.dll`
与本仓库安装后得到的那个文件 **SHA256 完全一致**（`9E9211F0…88650A`），所以来源可以验证。

**如果你认识名单里的人，或者你自己就是译者**：这里只是把安装流程做省事，没有任何据为己有的意思。
署名有误、想补名字、或者希望撤下，开个 issue 我就改。

## 版权与免责

- 本仓库只包含**脚本与文档**（MIT，见 [LICENSE](LICENSE)）。
- Fallout 1 的代码与资源 © Bethesda Softworks / Interplay；简体中文文本
  © 《异尘余生汉化包》的各位作者（见上）；hi-res 补丁 f1_res © Matt Wells。
- 原汉化包的声明是「版权归其开发者共同所有，**未经许可，请勿用于任何商业目的**」——
  本包免费分发、不捆绑任何盈利内容，就是为了守住这条。
- 汉化文件本身不随本仓库分发，需要你自备。请只对自己拥有的正版游戏使用。
- 若在公开仓库/Release 里分发这些文件，可能触发 DMCA 下架或账号处罚 —— 那是你的选择，风险自负。

---

## English summary

A repeatable installer that turns a legit Steam copy of **Fallout 1** (appid 38400)
into the Simplified Chinese + 2560×1440 windowed version, with a byte-exact
rollback.

- `install.cmd` — locates the Steam library (registry + `libraryfolders.vdf` +
  drive scan), backs up every file it overwrites into `backup\<timestamp>\`
  with a `manifest.json`, copies 750 files, rewrites `f1_res.ini`
  (including `path=`), creates two desktop shortcuts. Hash-based, so re-running
  it is a no-op.
- `uninstall.cmd` — restores from the manifest, deletes added files, prunes
  empty folders.
- `fallout_chinese_windowed.ps1` — launches the game and pre-loads
  `fallout_font.dll` via `CreateRemoteThread` (the DX9 renderer crashes with
  `0xc0000005` if it draws text before that import slot is filled), then resizes
  the window to the requested client size and restores the ini on exit.

The Simplified Chinese text and the font loader come from the 2007 fan
translation 「异尘余生汉化包」 by 13号避难所 (bn13.com) — program by **noword**,
translators credited in the 致谢 section above; the hi-res patch is Matt Wells'
(Mash) Fallout High Resolution Patch. Neither is redistributed here
(copyright); see [`payload/README.md`](payload/README.md) for how to supply them.

